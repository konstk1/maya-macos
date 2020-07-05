//
//  VideoPlayer.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/4/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI
import AVKit
import AVFoundation
import SwiftyBeaver

struct VideoPlayerView: NSViewRepresentable {
    let fileName: String
    let fileExtension: String

    init(named: String, withExtension: String) {
        fileName = named
        fileExtension = withExtension
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<VideoPlayerView>) {
    }

    func makeNSView(context: Context) -> NSView {
        return LoopingPlayerNSView(named: fileName, withExtension: fileExtension)
    }
}

class LoopingPlayerNSView: NSView {
    private let playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(named fileName: String, withExtension fileExtension: String) {
        super.init(frame: .zero)

        // Load the resource
        guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            log.error("File \(fileName).\(fileExtension) doesn't exist inthe bundle.")
            return
        }

        let asset = AVAsset(url: fileUrl)
        let item = AVPlayerItem(asset: asset)

        // Setup the player
        let player = AVQueuePlayer()
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect

        if layer == nil {
            layer = CALayer()
        }

        layer?.addSublayer(playerLayer)

        // Create a new player looper with the queue player and template item
        playerLooper = AVPlayerLooper(player: player, templateItem: item)

        // Start the movie
        player.play()
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
