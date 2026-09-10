//
//  Appearance.swift
//  Umless
//
//  Light / dark preference: follow the system, or pick one in Settings.
//

import Observation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    var id: String { rawValue }

    /// `nil` hands the decision back to the system, which is what
    /// `preferredColorScheme` wants for "don't override".
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    @MainActor
    var displayName: String {
        switch self {
        case .system: loc("Follow System")
        case .light: loc("Light")
        case .dark: loc("Dark")
        }
    }
}

/// The appearance preference, persisted and applied while the app runs.
///
/// Kept separate from ``Localization`` rather than folded into one settings
/// object: they change independently, and observing them separately means a
/// language switch doesn't invalidate views that only care about the theme.
@MainActor
@Observable
final class Appearance {
    static let shared = Appearance()

    private static let defaultsKey = "UmlessTheme"

    var theme: AppTheme {
        didSet {
            guard theme != oldValue else { return }
            UserDefaults.standard.set(theme.rawValue, forKey: Self.defaultsKey)
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.defaultsKey)
        theme = stored.flatMap(AppTheme.init(rawValue:)) ?? .system
    }
}
