//
//  ReleaseCheck.swift
//  Umless
//
//  The app's App Store identity, and whether a newer build is live.
//

import Foundation

/// Looks the app up on the App Store to see whether the installed build is the
/// current one.
///
/// Used on iOS, where the app cannot update itself and the only useful thing to
/// do is point the user at the store. macOS does not call `latest()`: the Mac
/// side takes the user straight to its product page instead, so the Mac app
/// makes no network request of its own.
///
/// The lookup endpoint is a public, unauthenticated Apple service. It is sent
/// nothing but the app's own numeric ID — no identifier for the user, the
/// device, or anything they have opened.
nonisolated enum ReleaseCheck {

    /// App Store Connect ID for Umless.
    static let appStoreID = "6810557305"

    static var productPageURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    }

    /// Opens the product page with the rating sheet already up, for the user who
    /// goes looking for it rather than waiting to be asked.
    static var writeReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }

    static var installedVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    enum Outcome: Equatable {
        case upToDate
        /// A newer build is on the store, with its version string.
        case updateAvailable(String)
        /// The store could not be reached, or does not list the app yet — which
        /// is the normal answer before the first release is approved. Never
        /// reported to the user as an update.
        case unknown
    }

    static func latest() async -> Outcome {
        guard var components = URLComponents(
            string: "https://itunes.apple.com/lookup") else { return .unknown }
        components.queryItems = [URLQueryItem(name: "id", value: appStoreID)]
        guard let url = components.url else { return .unknown }

        // The lookup sits behind a CDN that will happily serve a stale answer
        // for a long time, which is exactly wrong for "is there a new build" —
        // so this asks for a fresh one. The short timeout keeps a launch-time
        // check from hanging when the network is bad.
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let payload = try? JSONDecoder().decode(LookupResponse.self, from: data),
              let store = payload.results.first
        else { return .unknown }

        guard isNewer(store.version, than: installedVersion) else { return .upToDate }
        // The minimum reaches back to iOS 17, so a later release that raises it
        // would otherwise be offered — every day — to people whose phones cannot
        // install it. A build this device cannot run is not an update it can act
        // on; for this device, what it has is the latest.
        if let required = store.minimumOsVersion,
           !canRun(minimumOS: required) { return .upToDate }
        return .updateAvailable(store.version)
    }

    /// Whether this device's OS meets a store build's minimum.
    static func canRun(minimumOS required: String,
                       on system: String = currentOSVersion) -> Bool {
        !isNewer(required, than: system)
    }

    static var currentOSVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    /// Compares two dotted version strings numerically, so 1.0.10 sorts above
    /// 1.0.9 rather than below it the way a plain string comparison would.
    static func isNewer(_ candidate: String, than installed: String) -> Bool {
        candidate.compare(installed, options: .numeric) == .orderedDescending
    }

    private struct LookupResponse: Decodable {
        let results: [StoreEntry]
        struct StoreEntry: Decodable {
            let version: String
            /// The iOS floor of that build — the lookup describes the iOS app.
            let minimumOsVersion: String?
        }
    }
}
