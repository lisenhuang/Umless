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

Twelve files are **byte-identical copies** in both `Umless/` folders, as is
`UhmModel.bundle`:

```
SourceVideo    AudioExtractor   CutPlan       VideoExporter
FillerAnalyzer UmlessError      AppModel      PlayerController
TimelineBar    ProgressThrottle Localization  Appearance
```

Change one and the edit is only half done. Copy it across, then prove it:

```sh
diff -r Mac/Umless iOS/Umless   # engine files must not appear
```

`Localizable.xcstrings` is **not** one of them. The shared keys carry identical
translations, but each side adds its own copy — "this Mac's Neural Engine"
against "this device's", "Show in Finder" against "Save to Photos". Add a key to
the side that uses it; never copy the catalogue across.

Only the UI is allowed to differ — `ContentView`, `SettingsView`,
`FillerListView`, `PlayerLayerView`, `UmlessApp`, plus `Sidebar` (macOS only)
and `ExportBar` / `VideoLibrary` (iOS only).

**The two projects carry the same version.** Bumping one means bumping the
other, whether or not its code changed. See either project's `CLAUDE.md`.

## Things that will bite

- **The simulator is not the device.** iOS encodes AAC in hardware on a device
  and in software on the simulator, and the two accept different PCM input. An
  export path can pass every test and still fail in your hand.
- **A track's format description describes the *encoded* audio, not the decoded
  audio.** HE-AAC reports half its real sample rate (SBR supplies the rest) and
  HE-AAC v2 also reports half its channels. Configuring an export from those
  numbers silently halves the audio and hands the encoder a bit rate it refuses
  mid-export. `SourceVideo` decodes a buffer and reads the format off that.
- **Ask the AAC encoder what it accepts, never a formula.** The legal bit rates
  narrow sharply as the sample rate drops — 256 kbps is fine at 44.1 kHz and
  refused at 22.05 — and a refusal arrives as a failed `append` half-way
  through, not as a rejected setting. `kAudioConverterApplicableEncodeBitRates`
  gives the real list.
- **Export format fidelity is the product.** Width, height, frame rate,
  rotation and colour tags are copied off the source — hence
  `AVAssetReader`/`AVAssetWriter` rather than `AVAssetExportSession`, whose
  presets pick their own dimensions. Verify a real export with `ffprobe`, not
  by reading the code.
- **Cut boundaries are integer frame ticks.** `CutPlan` and `VideoExporter`
  must snap on the same frame rate, or joins drift by a fraction of a frame.
- **The model must stay a `.bundle`.** A bare `.mlmodel` gets compiled and
  renamed by Xcode, which breaks the SDK's filename lookup.
