# Umless — macOS

Cuts the "um"s out of a video and re-exports it at the source's own resolution
and frame rate. Detection is the on-device Uhm model (Core ML), shipped inside
the app as `Umless/UhmModel.bundle`; nothing is uploaded and nothing is
downloaded.

## Versioning — bump on every change

Every time you modify code here, bump both numbers in
`Umless.xcodeproj/project.pbxproj`, as part of the same change:

- `CURRENT_PROJECT_VERSION` (build number) — +1.
- `MARKETING_VERSION` — +1 on the patch component (1.0.1 -> 1.0.2). Bump the
  minor component for a new feature instead, the major for a release.

One bump per round of work, not per file. Both keys appear once per build
configuration, so every occurrence has to move together:

```sh
sed -i '' 's/CURRENT_PROJECT_VERSION = 1;/CURRENT_PROJECT_VERSION = 2;/g;
           s/MARKETING_VERSION = 1.0;/MARKETING_VERSION = 1.0.1;/g' \
  Umless.xcodeproj/project.pbxproj
```

**macOS and iOS carry the same version.** Bump the sibling project (`../iOS`) to
match, whether or not its code changed. If the two have drifted, raise both to
the higher of the two and carry on from there.

## The sibling project

The app is two independent Xcode projects with no shared package:

- macOS — `../Mac` (here)
- iOS — `../iOS`

Twelve engine files are **byte-identical copies** in both `Umless/` folders:
`SourceVideo`, `AudioExtractor`, `CutPlan`, `VideoExporter`, `FillerAnalyzer`,
`UmlessError`, `ProgressThrottle`, `Localization`, `PlayerController`,
`AppModel`, `TimelineBar`, `Appearance` — as is `UhmModel.bundle`.

`Localizable.xcstrings` is **not** one of them: the shared keys carry identical
translations, but each platform adds its own copy ("this Mac's Neural Engine"
against "this device's", "Show in Finder" against "Save to Photos"). Add a key
to the side that uses it; never copy the catalogue across. Change one and you must copy it across; `diff` the two
`Umless/` folders before calling the change done.

Platform-specific: macOS has `Sidebar.swift`; iOS has `ExportBar.swift` and
`VideoLibrary.swift`. `ContentView`, `SettingsView`, `FillerListView`,
`PlayerLayerView` and `UmlessApp` exist in both and differ.

## Build and test

```sh
xcodebuild -project Umless.xcodeproj -scheme Umless \
  -destination 'platform=macOS' build
xcodebuild -project Umless.xcodeproj -scheme Umless \
  -destination 'platform=macOS' -only-testing:UmlessTests test
```

`-only-testing:UmlessTests` is deliberate: the two boilerplate `UmlessUITests`
fail for environmental reasons (a Grammarly service blocks XCUITest on this
machine), not because of anything in the app.

## Things that will bite

- **The model must stay a `.bundle`.** A bare `.mlmodel` in a synchronized
  group gets compiled and renamed by Xcode, which breaks the SDK's filename
  lookup. The folder wrapper is copied into the app verbatim instead.
- **Export format fidelity is the product.** Width, height, frame rate,
  rotation and colour tags are all copied off the source — hence
  `AVAssetReader`/`AVAssetWriter` rather than `AVAssetExportSession`, whose
  presets choose their own dimensions. Verify a real export with `ffprobe`,
  not by reading the code.
- **Cut boundaries are integer frame ticks.** `CutPlan` and `VideoExporter`
  must snap on the same frame rate, or joins drift by a fraction of a frame and
  duplicate frames appear at the seams.
- **Progress reports arrive late.** They are produced on background queues and
  hop to the main actor, so `AppModel` checks a run token before applying one;
  a stale report otherwise re-raises a finished stage and pins the progress
  overlay on screen.
