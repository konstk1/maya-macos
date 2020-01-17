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

final class GooglePhotoProvider {
    static let shared = GooglePhotoProvider()
    
    weak var delegate: PhotoProviderDelegate?
    
    private lazy var alamo = Session(interceptor: oauthswift.requestInterceptor)
    
    private let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenURL = "https://www.googleapis.com/oauth2/v4/token"
    private let scope = "https://www.googleapis.com/auth/photoslibrary.readonly"
    private let callbackURL = URL(string: "com.kk.maya-macos:/oauth-callback/google")!
    
    private let baseURL = URL(string: "https://photoslibrary.googleapis.com/v1/")!
    
    private(set) var albums: [GooglePhotos.Album] = []
    
    private var activeAlbum: GooglePhotos.Album?
    
    /// Photos in active album
    private(set) var photos: [GooglePhotos.MediaItem] = []
    
    lazy var photoCountPublisher = CurrentValueSubject<Int, Never>(photos.count)
    
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
    
    private init() {
        log.verbose("Google Photo Provider init")
        if let token = oauthToken, let refreshToken = oauthRefreshToken {
            oauthswift.client.credential.oauthToken = token
            oauthswift.client.credential.oauthRefreshToken = refreshToken
        }
        
        if let activeAlbumId = Settings.googlePhotos.activeAlbumId {
            activeAlbum = GooglePhotos.Album(id: activeAlbumId, title: "Loading...", productUrl: "", mediaItemsCount: nil, coverPhotoBaseUrl: "", coverPhotoMediaItemId: nil)
            listPhotos(for: activeAlbum!) { [weak self] _ in
                self?.delegate?.didUpdateAssets(assets: self?.photoDescriptors ?? [])
            }
        }
    }
    
    func setActiveAlbum(album: GooglePhotos.Album) {
        activeAlbum = album
        // persist active album selection
        Settings.googlePhotos.activeAlbumId = album.id
        
        listPhotos(for: album) { [weak self] result in
            self?.delegate?.didUpdateAssets(assets: self?.photoDescriptors ?? [])
        }
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
    
    func authorize(completion: @escaping (Result<Void, PhotoProviderError>) -> Void) {
        let authCompletionHandler: OAuthSwift.TokenCompletionHandler = { [weak self] result in
            switch result {
            case .success(let (credential, _, _)):
                self?.oauthToken = credential.oauthToken
                self?.oauthTokenExpiresAt = credential.oauthTokenExpiresAt
                self?.oauthRefreshToken = credential.oauthRefreshToken
                log.verbose("Auth success done")
            case .failure(let error):
                switch error {
                case .configurationError(let message):
                    print(message)
                default:
                    print(error.localizedDescription)
                }
            }
            // convert OAuthSwiftResult into our own
            let newResult = result.flatMap { _ in .success(()) }.flatMapError { _ in .failure(PhotoProviderError.failedAuth) }
            completion(newResult)
        }
        
        if isAuthorized {
            log.verbose("Current token is valid")
            completion(.success(()))
            return
        }
        else if let refreshToken = oauthRefreshToken {
            log.verbose("Refreshing...")
            oauthswift.renewAccessToken(withRefreshToken: refreshToken, completionHandler: authCompletionHandler)
        } else {
            log.verbose("Authorizing...")
            // if neither token nor refresh token are valid, need to re-authorize from scratch
            let state = generateState(withLength: 20)
            oauthswift.authorize(withCallbackURL: callbackURL, scope: scope, state: state, completionHandler: authCompletionHandler)
        }
    }
    
    func listAlbums(pageToken: String? = nil, completion: @escaping (Result<[GooglePhotos.Album], Error>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("albums")
        let params = GooglePhotos.Albums.ListRequest(pageToken: pageToken)
        
        // if not continuing pagination, reset album list
        if pageToken == nil {
            albums.removeAll()
        }
        
        log.debug("Requesting \(endpoint.absoluteString)")
        alamo.request(endpoint, parameters: params).validate().responseDecodable { [weak self] (response: AFDataResponse<GooglePhotos.Albums.ListResponse>) in
            log.debug("Fetching \(response.request!.url!.absoluteString)")
            guard let strongSelf = self else { return }
            switch response.result {
            case .success(let albumList):
                strongSelf.albums.append(contentsOf: albumList.albums)
                if let nextPageToken = albumList.nextPageToken {
                    strongSelf.listAlbums(pageToken: nextPageToken, completion: completion)
                } else {
                    print("Success: \(strongSelf.albums.count) albums")
                    strongSelf.updateActiveAlbumDetails()
                    completion(.success(strongSelf.albums))
                }
            case .failure(let error):
                log.error("Album list failed: HTTP \(response.response?.statusCode ?? 0) - \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func listPhotos(for album: GooglePhotos.Album, pageToken: String? = nil, completion: @escaping (Result<[GooglePhotos.MediaItem], Error>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("mediaItems:search")
        let params = GooglePhotos.Albums.ContentsRequest(albumId: album.id, pageToken: pageToken)
        
        if pageToken == nil {
            photos.removeAll()
        }
        
        alamo.request(endpoint, method: .post, parameters: params).validate().responseDecodable { [weak self] (response: AFDataResponse<GooglePhotos.Albums.ContentsResponse>) in
            log.debug("Fetching \(response.request!.url!.absoluteString)")
            guard let strongSelf = self else { return }
            switch response.result {
            case .success(let contents):
                let photos = contents.mediaItems.filter { $0.isPhoto }  // filter out non-photo items
                strongSelf.photos.append(contentsOf: photos)
                if let nextPageToken = contents.nextPageToken {
                    strongSelf.listPhotos(for: album, pageToken: nextPageToken, completion: completion)
                } else {
                    print("Success: photos \(strongSelf.photos.count)")
                    NotificationCenter.default.post(name: .updatePhotoCount, object: self, userInfo: ["photoCount": photos.count])
                    strongSelf.photoCountPublisher.send(photos.count)
                    completion(.success(strongSelf.photos))
                }
            case .failure(let error):
                log.error("Failed to get contents of album \(album.title): \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func getMediaItem(id: String, completion: @escaping (Result<GooglePhotos.MediaItem, AFError>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("mediaItems/\(id)")
        print("Fetching \(endpoint.absoluteString)")
        alamo.request(endpoint).validate().responseDecodable { (response: AFDataResponse<GooglePhotos.MediaItem>) in
            // pass result directly to callback
            completion(response.result)
        }
    }
    
//    func downloadImage(baseURL: URL, completion: @escaping (Result<NSImage, Error>) -> Void) {
////        let endpoint = baseURL.appendingPathExtension("=wMAX_WIDTH-hMAX_HEIGHT")
//        let endpoint = baseURL
//        alamo.download(endpoint).validate().response { (response) in
//            print(response.fileURL)
//            let image = NSImage(contentsOf: <#T##URL#>)
//            completion
//        }
//    }
    
    func getPhoto(id: String, completion: @escaping (Result<NSImage, Error>) -> Void) {
        getMediaItem(id: id) { (result) in
            switch result {
            case .success(let mediaItem):
                if let image = NSImage(contentsOf: URL(string: mediaItem.baseUrl)!) {
                    completion(.success(image))
                } else {
                    completion(.failure(PhotoProviderError.failedFetchURL))
                }
            case .failure(let error):
                log.error("Failed to get media item: \(error)")
                completion(.failure(error))
            }
        }
    }
}

extension GooglePhotoProvider: PhotoProvider {    
    var photoDescriptors: [PhotoAssetDescriptor] {
        return photos.map { GooglePhotoAsset(photoId: $0.id) }
    }
    
    func refreshAssets(completion: @escaping (Result<[PhotoAssetDescriptor], Error>) -> Void) {
        let google = GooglePhotoProvider.shared
        
        if let activeAlbum = google.activeAlbum {
            GooglePhotoProvider.shared.listPhotos(for: activeAlbum) { (result) in
                let newResult = result.map { (photos) -> [PhotoAssetDescriptor] in
                    self.photos = photos
                    return self.photoDescriptors
                }
                completion(newResult)
            }
        } else {
            // if no active album, return failure
            completion(.failure(PhotoProviderError.noActiveAlbum))
        }
    }
}
