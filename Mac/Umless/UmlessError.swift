//
//  UmlessError.swift
//  Umless
//

import Foundation

nonisolated enum UmlessError: LocalizedError {
    case noVideoTrack
    case noAudioTrack
    case readFailed(String)
    case writeFailed(String)
    case nothingLeft
    case modelMissing

    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            LocalizationCore.string("That file doesn’t contain a video track Umless can read.")
        case .noAudioTrack:
            LocalizationCore.string("That video has no audio track, so there’s nothing to listen to for filler words.")
        case .readFailed(let detail):
            String(format: LocalizationCore.string("Couldn’t read the video: %@"), detail)
        case .writeFailed(let detail):
            String(format: LocalizationCore.string("Couldn’t write the exported video: %@"), detail)
        case .nothingLeft:
            LocalizationCore.string("Every selected cut together removes the whole video — deselect a few and try again.")
        case .modelMissing:
            LocalizationCore.string("The filler-detection model is missing from this copy of Umless. Reinstall the app.")
        }
    }
}
