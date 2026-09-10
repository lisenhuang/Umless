# Umless

Cuts the "um"s out of a video and re-exports it at the source's own resolution,
frame rate, rotation and colour. Detection is an on-device Core ML model
shipped inside the app; nothing is uploaded and nothing is downloaded.

## Layout

Two **independent Xcode projects** in one repo, with no shared package and no
workspace tying them together:

| Platform | Project | Build destination |
| --- | --- | --- |
| macOS | `Mac/Umless.xcodeproj` | `platform=macOS` |
| iOS | `iOS/Umless.xcodeproj` | `platform=iOS Simulator,name=iPhone 17,OS=26.5` |

Each project has its own `CLAUDE.md` with the build commands, the versioning
rule and the platform's own traps. Read the one for the side you are touching.

## The rule that matters: the engine is copied, not shared

Twelve files are **byte-identical copies** in both `Umless/` folders, as are
`UhmModel.bundle` and `Localizable.xcstrings`:

```
SourceVideo    AudioExtractor   CutPlan       VideoExporter
FillerAnalyzer UmlessError      AppModel      PlayerController
TimelineBar    ProgressThrottle Localization  Appearance
```

Change one and the edit is only half done. Copy it across, then prove it:

```sh
diff -r Mac/Umless iOS/Umless   # engine files must not appear
```

Only the UI is allowed to differ — `ContentView`, `SettingsView`,
`FillerListView`, `PlayerLayerView`, `UmlessApp`, plus `Sidebar` (macOS only)
and `ExportBar` / `VideoLibrary` (iOS only).

**The two projects carry the same version.** Bumping one means bumping the
other, whether or not its code changed. See either project's `CLAUDE.md`.

## Things that will bite

- **The simulator is not the device.** iOS encodes AAC in hardware on a device
  and in software on the simulator, and the two accept different PCM input. An
  export path can pass every test and still fail in your hand.
- **Export format fidelity is the product.** Width, height, frame rate,
  rotation and colour tags are copied off the source — hence
  `AVAssetReader`/`AVAssetWriter` rather than `AVAssetExportSession`, whose
  presets pick their own dimensions. Verify a real export with `ffprobe`, not
  by reading the code.
- **Cut boundaries are integer frame ticks.** `CutPlan` and `VideoExporter`
  must snap on the same frame rate, or joins drift by a fraction of a frame.
- **The model must stay a `.bundle`.** A bare `.mlmodel` gets compiled and
  renamed by Xcode, which breaks the SDK's filename lookup.
