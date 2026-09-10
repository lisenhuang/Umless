//
//  VideoLibrary.swift
//  Umless
//
//  Getting a video in from Photos, and the finished cut back out to it.
//

import AVFoundation
import CoreTransferable
import Photos
import SwiftUI

/// A movie pulled out of the photo picker.
///
/// `PhotosPickerItem` hands over bytes, not a path, and the whole pipeline —
/// `AVAsset`, the reader, the exporter — works from a file URL, so the payload
/// is written to a temporary file and that URL is what travels on.
struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("umless-import-\(UUID().uuidString)")
                .appendingPathExtension(received.file.pathExtension.isEmpty
                                        ? "mov" : received.file.pathExtension)
            // The received file is deleted as soon as this closure returns.
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedMovie(url: destination)
        }
    }
}

enum PhotoLibraryError: LocalizedError {
    case notPermitted

    var errorDescription: String? {
        LocalizationCore.string("Umless needs permission to save videos to your photo library. You can grant it in Settings.")
    }
}

enum VideoLibrary {
    /// Asks for permission to add to the photo library.
    ///
    /// Add-only: Umless writes one video and never reads the library, so the
    /// broader read-write permission would be more than the feature needs.
    /// Once the user has answered, asking again returns their answer without
    /// showing anything, which is what lets the prompt be moved to a moment
    /// they are expecting one.
    @discardableResult
    static func requestAddAccess() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }

    /// Saves the exported file into the user's photo library.
    static func save(_ url: URL) async throws {
        let status = await requestAddAccess()
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.notPermitted
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
}
