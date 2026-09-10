//
//  LocalizationTests.swift
//  UmlessTests
//

import Foundation
import Testing
@testable import Umless

struct LocalizationTests {

    // MARK: Which language a system setting resolves to

    @Test("Every Chinese system resolves to Simplified",
          arguments: ["zh-Hans", "zh-Hans-CN", "zh-CN",
                      "zh-Hant", "zh-Hant-TW", "zh-TW", "zh-HK", "zh-Hant-HK"])
    func chineseSystemsGetSimplified(code: String) {
        #expect(LocalizationCore.code(for: .system, preferredLanguages: [code]) == "zh-Hans",
                "\(code) should show Simplified Chinese")
    }

    @Test("English systems get English",
          arguments: ["en", "en-US", "en-GB", "en-AU"])
    func englishSystemsGetEnglish(code: String) {
        #expect(LocalizationCore.code(for: .system, preferredLanguages: [code]) == "en")
    }

    @Test("An unshipped language falls back to English",
          arguments: ["ja-JP", "ko-KR", "fr-FR", "de-DE", "es-ES"])
    func unshippedLanguagesFallBack(code: String) {
        #expect(LocalizationCore.code(for: .system, preferredLanguages: [code]) == "en")
    }

    @Test func fallsBackToEnglishWithNoPreferences() {
        #expect(LocalizationCore.code(for: .system, preferredLanguages: []) == "en")
    }

    @Test func honoursTheOrderOfPreferredLanguages() {
        // Chinese first, so Chinese wins even with English also installed.
        #expect(LocalizationCore.code(for: .system, preferredLanguages: ["zh-Hant-TW", "en-US"]) == "zh-Hans")
        #expect(LocalizationCore.code(for: .system, preferredLanguages: ["en-US", "zh-Hans"]) == "en")
        // An unshipped language is skipped rather than falling straight to English.
        #expect(LocalizationCore.code(for: .system, preferredLanguages: ["ko-KR", "zh-TW"]) == "zh-Hans")
    }

    @Test func anExplicitChoiceIgnoresTheSystem() {
        #expect(LocalizationCore.code(for: .english, preferredLanguages: ["zh-Hant-TW"]) == "en")
        #expect(LocalizationCore.code(for: .simplifiedChinese, preferredLanguages: ["en-US"]) == "zh-Hans")
    }

    // MARK: The copy is actually in the app

    @Test func everyLocalizationIsBuiltIntoTheApp() {
        for code in ["en", "zh-Hans", "zh-Hant"] {
            let bundle = LocalizationCore.bundle(for: code)
            #expect(bundle != Bundle.main, "\(code).lproj is missing from the app")
        }
    }

    /// `zh-Hant` exists so macOS treats Umless as localized for a Traditional
    /// system and renders the menu bar it supplies in Chinese. It carries the
    /// Simplified copy verbatim, so it must not drift from `zh-Hans`.
    @Test func traditionalCarriesTheSimplifiedCopy() throws {
        #expect(try strings(for: "zh-Hant") == (try strings(for: "zh-Hans")))
    }

    @Test func chineseCopyResolvesThroughTheBundle() {
        let zh = LocalizationCore.bundle(for: "zh-Hans")
        #expect(String(localized: "Cancel", bundle: zh) == "取消")
        #expect(String(localized: "Export Video", bundle: zh) == "导出视频")
        #expect(String(localized: "Choose Video", bundle: zh) == "选择视频")
    }

    @Test func englishCopyResolvesThroughTheBundle() {
        let en = LocalizationCore.bundle(for: "en")
        #expect(String(localized: "Cancel", bundle: en) == "Cancel")
        #expect(String(localized: "Export Video", bundle: en) == "Export Video")
    }

    /// The two catalogs must cover exactly the same keys, or a Chinese user
    /// hits stray English mid-sentence.
    @Test func bothLanguagesCoverTheSameKeys() throws {
        let english = try strings(for: "en")
        let chinese = try strings(for: "zh-Hans")

        #expect(english.count > 50, "expected the full catalog, found \(english.count) keys")
        #expect(Set(english.keys) == Set(chinese.keys))
        #expect(Set(english.keys) == Set(try strings(for: "zh-Hant").keys))
        for (key, value) in chinese {
            #expect(!value.isEmpty, "“\(key)” has an empty Chinese translation")
        }
    }

    private func strings(for code: String) throws -> [String: String] {
        let bundle = LocalizationCore.bundle(for: code)
        let path = try #require(bundle.path(forResource: "Localizable", ofType: "strings"),
                                "\(code).lproj has no compiled strings")
        return try #require(NSDictionary(contentsOfFile: path) as? [String: String])
    }
}
