//
//  Localization.swift
//  Umless
//
//  Language selection: follow the system, or pick one in Settings.
//

import Foundation
import Observation

/// The languages Umless ships, plus "whatever the system is using".
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }
}

/// The bundle the app reads its copy from, and the rules for choosing it.
///
/// Split out from ``Localization`` because it has to be reachable from
/// non-UI code — `UmlessError` builds its messages off the main actor — so it
/// cannot be main-actor isolated the way the observable settings object is.
enum LocalizationCore {
    /// Shipped when nothing else matches. Also the source language, so its
    /// strings exist even if a `.lproj` fails to load.
    static let fallback = AppLanguage.english.rawValue

    private nonisolated(unsafe) static var storedBundle = Bundle.main
    private static let lock = NSLock()

    static var bundle: Bundle {
        get { lock.withLock { storedBundle } }
        set { lock.withLock { storedBundle = newValue } }
    }

    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: bundle)
    }

    /// The language code to load for a preference.
    ///
    /// `.system` walks the user's preferred languages in order. Every Chinese
    /// locale resolves to Simplified — `zh-Hant`, `zh-TW` and `zh-HK`
    /// included. That is deliberate: Simplified is the only Chinese Umless
    /// ships, and it reads far closer for a Traditional user than the English
    /// they would otherwise fall through to.
    ///
    /// The app also ships a `zh-Hant` localization holding that same Simplified
    /// copy. It is not redundant: without it macOS would not count Umless as
    /// localized for a Traditional system and would render the menu bar it
    /// supplies (About, Services, Quit) in English, next to a Chinese UI.
    static func code(for language: AppLanguage,
                     preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        guard language == .system else { return language.rawValue }
        for preferred in preferredLanguages {
            let code = preferred.lowercased()
            if code.hasPrefix("zh") { return AppLanguage.simplifiedChinese.rawValue }
            if code.hasPrefix("en") { return fallback }
        }
        return fallback
    }

    /// The `.lproj` for a code, or the main bundle when it isn't built in.
    static func bundle(for code: String) -> Bundle {
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }
}

/// The language preference, persisted and switchable while the app runs.
@MainActor
@Observable
final class Localization {
    static let shared = Localization()

    private static let defaultsKey = "UmlessLanguage"

    var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            UserDefaults.standard.set(language.rawValue, forKey: Self.defaultsKey)
            apply()
        }
    }

    /// The code actually in effect — what `.system` resolved to, when that is
    /// the preference.
    var resolvedCode: String { LocalizationCore.code(for: language) }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.defaultsKey)
        language = stored.flatMap(AppLanguage.init(rawValue:)) ?? .system
        apply()
    }

    private func apply() {
        LocalizationCore.bundle = LocalizationCore.bundle(for: resolvedCode)
    }

    /// Copy in the active language.
    ///
    /// Touching `language` here is load-bearing: it is what registers a
    /// SwiftUI view that displays text as a reader of the preference, so
    /// changing the picker re-renders the whole app rather than only Settings.
    func callAsFunction(_ key: String.LocalizationValue) -> String {
        _ = language
        return LocalizationCore.string(key)
    }
}

/// Shorthand for the active language's copy, for use inside a `View` body.
@MainActor
func loc(_ key: String.LocalizationValue) -> String {
    Localization.shared(key)
}

extension AppLanguage {
    /// Name for the picker. The two real languages are written in their own
    /// script, which is what someone scanning for their language expects to
    /// find; only "follow the system" is translated.
    @MainActor
    var displayName: String {
        switch self {
        case .system: loc("Follow System")
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        }
    }
}
