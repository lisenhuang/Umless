//
//  PlayerLayerView.swift
//  Umless
//

import AVFoundation
import SwiftUI
import UIKit

/// Bare `AVPlayerLayer`, no controls — the transport lives in `TimelineBar`.
struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }

    /// Backing the view with `AVPlayerLayer` directly, rather than adding one
    /// as a sublayer, means the layer resizes with the view for free.
    final class PlayerUIView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }

        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
            playerLayer.videoGravity = .resizeAspect
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("not used") }
    }
}
