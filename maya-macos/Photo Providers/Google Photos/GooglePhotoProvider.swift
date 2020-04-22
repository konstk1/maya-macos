//
//  GooglePhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/28/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import Combine
import Alamofire
import OAuthSwift
import OAuthSwiftAlamofire
import KeychainAccess

final class GooglePhotoProvider: PhotoProvider {
    private lazy var alamo = Session(interceptor: oauthswift.requestInterceptor)
    
    private let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenURL = "https://www.googleapis.com/oauth2/v4/token"
    private let scope = "https://www.googleapis.com/auth/photoslibrary.readonly"
    private let callbackURL = URL(string: "com.kk.maya-macos:/oauth-callback/google")!

    private let baseURL = URL(string: "https://photoslibrary.googleapis.com/v1/")!
    
    private(set) var albums: [GooglePhotos.Album] = [] {
        didSet {
            print("Setting albums")
            albumsPublisher.send(albums)
        }
    }
    var albumsPublisher = CurrentValueSubject<[GooglePhotos.Album], Never>([])
    
    private var activeAlbum: GooglePhotos.Album?
    
    /// Photos in active album
    private var photos: [GooglePhotos.MediaItem] = []       // don't update photoDescriptors here on didSet because of pagination

    private lazy var oauthswift = OAuth2Swift(
        consumerKey: Secrets.GoogleAPI.clientId,
        consumerSecret: "",
        authorizeUrl: authURL,
        accessTokenUrl: tokenURL,
        responseType: "code"
    )
    
    @KeychainSecureString(key: "google-oauth-token") private var oauthToken: String?
    @KeychainSecureString(key: "google-oauth-refresh-token") private var oauthRefreshToken: String?
    private var oauthTokenExpiresAt: Date?
    
    /// Indicates whether current OAuth token is valid
    var isAuthorized: Bool {
        guard oauthToken != nil, let oauthTokenExpiresAt = oauthTokenExpiresAt else { return false }
        return oauthTokenExpiresAt > Date()
    }
    
    override init() {
        super.init()
        log.verbose("Google Photo Provider init")
        if let token = oauthToken, let refreshToken = oauthRefreshToken {
            oauthswift.client.credential.oauthToken = token
            oauthswift.client.credential.oauthRefreshToken = refreshToken
        }
        
        if let activeAlbumId = Settings.googlePhotos.activeAlbumId {
            activeAlbum = GooglePhotos.Album(id: activeAlbumId, title: "Loading...", productUrl: "", mediaItemsCount: nil, coverPhotoBaseUrl: "", coverPhotoMediaItemId: nil)
            refreshAssets()
        }
    }
    
    func setActiveAlbum(album: GooglePhotos.Album) {
        activeAlbum = album
        // persist active album selection
        Settings.googlePhotos.activeAlbumId = album.id
        
        listPhotos(for: album)
    }
    
    func updateActiveAlbumDetails() {
        guard let activeAlbum = activeAlbum else { return }
        guard let album = albums.first(where: { $0.id == activeAlbum.id }) else {
            log.error("Active album id doesn't exist in album list")
            return
        }
        
        // update active album with detailed version
        self.activeAlbum = album
    }
    
    func authorize() -> Future<Void, PhotoProviderError> {
        return Future { [weak self] promise in
            guard let self = self else { return }

            let authCompletionHandler: OAuthSwift.TokenCompletionHandler = { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let (credential, _, _)):
                    self.oauthToken = credential.oauthToken
                    self.oauthTokenExpiresAt = credential.oauthTokenExpiresAt
                    self.oauthRefreshToken = credential.oauthRefreshToken
                    log.verbose("Auth success done")
                case .failure(let error):
                    switch error {
                    case .configurationError(let message):
                        print("\(error) : message: \(message)")
                    default:
                        print("Unknown error: \(error) \(error.localizedDescription)")
                    }
                }
                // convert OAuthSwiftResult into our own
                let newResult = result
                    .map { _ -> Void in
                        self.handleError(error: nil)    // clear error
                        return ()                       // success result is just void
                } .mapError { _ in
                    // error is simply failed auth
                    self.handleError(error: PhotoProviderError.failedAuth)
                }

                promise(newResult)
            }

            if self.isAuthorized {
                log.verbose("Current token is valid")
                self.handleError(error: nil)
                promise(.success(()))
            }
            else if let refreshToken = self.oauthRefreshToken {
                log.verbose("Refreshing...")
                self.oauthswift.renewAccessToken(withRefreshToken: refreshToken, completionHandler: authCompletionHandler)
            } else {
                log.verbose("Authorizing...")
                // if neither token nor refresh token are valid, need to re-authorize from scratch
                let state = generateState(withLength: 20)
                self.oauthswift.authorize(withCallbackURL: self.callbackURL, scope: self.scope, state: state, completionHandler: authCompletionHandler)
            }
        }
    }

    @discardableResult
    func listAlbums() -> Future<[GooglePhotos.Album], PhotoProviderError> {
        return Future { [weak self] promise in
            self?.listAlbums(pageToken: nil) { result in
                let newResult = result.map { albums -> [GooglePhotos.Album] in
                    self?.handleError(error: nil)
                    return albums
                }.mapError { error -> PhotoProviderError in
                    let newError = PhotoProviderError.failedToListAlbums
                    self?.handleError(error: newError)
                    return newError
                }
                promise(newResult)
            }
        }
    }
    
    private func listAlbums(pageToken: String?, completion: @escaping (Result<[GooglePhotos.Album], Error>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("albums")
        let params = GooglePhotos.Albums.ListRequest(pageToken: pageToken)
        
        // if not continuing pagination, reset album list
        if pageToken == nil {
            albums.removeAll()
        }
        
        log.debug("Requesting \(endpoint.absoluteString)")
        alamo.request(endpoint, parameters: params).validate().responseDecodable { [weak self] (response: AFDataResponse<GooglePhotos.Albums.ListResponse>) in
            log.debug("Fetching \(response.request!.url!.absoluteString)")
            guard let self = self else { return }
            switch response.result {
            case .success(let albumList):
                self.albums.append(contentsOf: albumList.albums)
                if let nextPageToken = albumList.nextPageToken {
                    self.listAlbums(pageToken: nextPageToken, completion: completion)
                } else {
                    print("Success: \(self.albums.count) albums")
                    self.updateActiveAlbumDetails()
                    completion(.success(self.albums))
                }
            case .failure(let error):
//                log.debug(String(data: response.data!, encoding: .utf8))
                log.error("Album list failed: HTTP \(response.response?.statusCode ?? 0) - \(error)")
                completion(.failure(error))
            }
        }
    }

    @discardableResult
    func listPhotos(for album: GooglePhotos.Album) -> Future<[PhotoAssetDescriptor], PhotoProviderError> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            self.listPhotos(for: album, pageToken: nil, completion: { result in
                switch result {
                case .success(let photos):
                    // update descriptors to trigger the publisher
                    self.photoDescriptors = photos.map { GooglePhotoAsset(photoId: $0.id) }
                    self.handleError(error: nil)    // clear error
                    promise(.success(self.photoDescriptors))
                case .failure(let error):
                    // TODO: map AFError to PhotoProviderError
//                    print("List photos error: \(error)")

                    let newError = self.handleError(error: error)
                    promise(.failure(newError))
                }
            })
        }
    }
    
    private func listPhotos(for album: GooglePhotos.Album, pageToken: String? = nil, completion: @escaping (Result<[GooglePhotos.MediaItem], Error>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("mediaItems:search")
        let params = GooglePhotos.Albums.ContentsRequest(albumId: album.id, pageToken: pageToken)
        
        if pageToken == nil {
            photos.removeAll()
        }
        
        alamo.request(endpoint, method: .post, parameters: params).validate().responseDecodable { [weak self] (response: AFDataResponse<GooglePhotos.Albums.ContentsResponse>) in
            log.debug("Fetching \(response.request!.url!.absoluteString)")
            guard let self = self else { return }
            switch response.result {
            case .success(let contents):
                let photos = contents.mediaItems.filter { $0.isPhoto }  // filter out non-photo items
                self.photos.append(contentsOf: photos)
                if let nextPageToken = contents.nextPageToken {
                    self.listPhotos(for: album, pageToken: nextPageToken, completion: completion)
                } else {
                    print("Success: photos \(self.photos.count)")
                    NotificationCenter.default.post(name: .updatePhotoCount, object: self, userInfo: ["photoCount": photos.count])
                    self.handleError(error: nil)    // clear error
                    completion(.success(self.photos))
                }
            case .failure(let error):
                log.error("Failed to get contents of album \(album.title): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    private func getMediaItem(id: String, completion: @escaping (Result<GooglePhotos.MediaItem, AFError>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("mediaItems/\(id)")
        log.debug("Fetching \(endpoint.absoluteString)")
        alamo.request(endpoint).validate().responseDecodable { (response: AFDataResponse<GooglePhotos.MediaItem>) in
            // pass result directly to callback
            completion(response.result)
        }
    }
    
    func getPhoto(id: String) -> Future<NSImage, PhotoProviderError> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            self.getMediaItem(id: id) { result in
                let newResult = result
                    .mapError { $0 as Error } // cast from AFError to Error
                    .flatMap { mediaItem -> Result<NSImage, Error> in
                        if let image = NSImage(contentsOf: URL(string: mediaItem.baseUrl)!) {
                            self.handleError(error: nil)    // clear error
                            return .success(image)
                        } else {
                            return .failure(PhotoProviderError.failedFetchURL)
                        }
                    }
                    .mapError { return self.handleError(error: $0) }

                promise(newResult)
            }
        }
    }

    @discardableResult
    override func refreshAssets() -> Future<[PhotoAssetDescriptor], PhotoProviderError> {
        guard let activeAlbum = activeAlbum else {
            error = .noActiveAlbum
            return Future { $0(.failure(.noActiveAlbum))}
        }

        return listPhotos(for: activeAlbum)
    }


    /// Handles error by mapping to corresponding PhotoProviderError and updating the error publisher.
    /// - Parameter error: Arbitrary error.
    /// - Returns: The PhotoProvider error that best represents specified `error`.
    @discardableResult
    private func handleError(error: Error?) -> PhotoProviderError {
        var nextError: PhotoProviderError = .unknown
        // TODO: map errors
        if error == nil {
            nextError = .none
        }
        if let error = error as? PhotoProviderError {
            nextError = error
        } else if let error = error as? AFError {
            log.debug("AFError: \(error)")
            if case .responseValidationFailed(let reason) = error {
                log.error("Response validation \(reason)")
            } else if let error = error.underlyingError as? OAuthSwiftError {
                switch error {
                case .requestError(let error as NSError, let request):
                    nextError = .unauthorized
                    log.error("Request: \(request) Error: \(error.localizedDescription)")
                default:
                    nextError = .failedAuth
                    log.error("Unexpected OAuth error: \(error.localizedDescription)")
                    break
                }
            }
        }

        self.error = nextError
        return nextError
    }
}
