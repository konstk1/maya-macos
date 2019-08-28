//
//  GooglePhotosAPI.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

enum GooglePhotos {
    enum Albums {
        struct ListRequest: Encodable {
            /// Maximum number of albums to return in the response. The default number of albums to return at a time is 20. The maximum pageSize is 50.
            let pageSize: Int = 50
            /// A continuation token to get the next page of the results. Adding this to the request returns the rows after the **pageToken**.
            /// The **pageToken** should be the value returned in the **nextPageToken** parameter in the response to the **listAlbums** request.
            let pageToken: String?
            /// If set, the results exclude media items that were not created by this app. Defaults to false (all albums are returned).
            /// This field is ignored if the photoslibrary.readonly.appcreateddata scope is used.
            let excludeNonAppCreatedData: Bool? = false
        }
        
        struct ListResponse: Decodable {
            let albums: [Album]
            /// Token to use to get the next set of albums. Populated if there are more albums to retrieve for this request.
            let nextPageToken: String?
        }
        
        struct ContentsRequest: Encodable {
            /// Identifier of an album. If populated, lists all media items in specified album. Can't set in conjunction with any filters.
            let albumId: String
            /// Maximum number of media items to return in the response. The default number of media items to return at a time is 25. The maximum pageSize is 100.
            let pageSize: Int = 100
            let pageToken: String?
        }
        
        struct ContentsResponse: Decodable {
            let mediaItems: [MediaItem]
            /// Use this token to get the next set of media items. Its presence is the only reliable indicator of more media items being available in the next request.
            let nextPageToken: String?
        }
    }
    
    struct Album: Decodable {
        let id: String
        let title: String
        let productUrl: String
        let mediaItemsCount: String?
        let coverPhotoBaseUrl: String
        let coverPhotoMediaItemId: String?
    }
    
    struct MediaItem: Decodable {
        let id: String
        let description: String?
        let baseUrl: String
        let mimeType: String
        let mediaMetadata: MediaMetaData
//        let contributorInfo
        let filename: String
        
        var isPhoto: Bool {
            mediaMetadata.photo != nil
        }
    }
    
    struct MediaMetaData: Decodable {
        let creationTime: String
        let width: String
        let height: String
        let photo: PhotoMetadata?
        let video: VideoMetadata?
    }
    
    struct PhotoMetadata: Decodable {
        // don't care about contents of this for now
    }
    
    struct VideoMetadata: Decodable {
        // don't care about contents of this for now
    }
    
    // BASE_URL=wMAX_WIDTH-hMAX_HEIGHT
}
