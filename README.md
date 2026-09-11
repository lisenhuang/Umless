# 🎬 Umless

**Cuts the "um"s out of your video.** Point it at a clip, it finds the filler
words, you pick which ones go, and it re-exports — same resolution, same frame
rate, same everything else. 🔒 Fully on-device: nothing uploaded, nothing
downloaded, no account.

---

## 📺 See it in action

A screen recording of the iPhone app, start to finish — pick a video, review
what it heard, export.

<a href="https://www.youtube.com/shorts/weP7U6hnRyg">
  <img src="https://img.youtube.com/vi/weP7U6hnRyg/maxresdefault.jpg"
       width="600" alt="Umless on iPhone — screen recording">
</a>

▶️ **[Watch on YouTube](https://www.youtube.com/shorts/weP7U6hnRyg)**

---

## ⚡️ How it works

```
   🎥 video
      │
      ▼
 ┌──────────────┐   16 kHz mono
 │ AudioExtract │ ──────────────┐
 └──────────────┘               ▼
                        ┌──────────────┐   "um" @ 1:12.00
                        │ 🧠 Uhm model │ ──────────────────┐
                        │  (Core ML)   │                   ▼
                        └──────────────┘            ┌─────────────┐
                                                    │ ✅ you pick │
                                                    └─────────────┘
                                                           │ keep ranges
                                                           ▼
   🎞 output  ◀────────────────────────────────────  ┌─────────────┐
              re-encode, source's own format         │ ✂️ CutPlan  │
                                                     └─────────────┘
```

The cuts land on **exact frame boundaries**, so no half-frames and no drift at
the seams. Export runs through `AVAssetReader` → `AVAssetWriter` rather than
`AVAssetExportSession`, because presets pick their own dimensions and the whole
point is that yours survive.

---

## 🧠 The model

Filler detection is **[Uhm](https://desertant.com/models/uhm/)** by
**[Desert Ant Labs](https://desertant.com)** — a 45 MB Core ML model bundled in
the app, loaded through the `desert-ant-core` SwiftPM package.

### Commercial use: allowed, with conditions

Licence is [**DAL Source-Available 1.0**](https://license.desertant.com/1.0)
(`LicenseRef-DAL-Source-Available-1.0`) — source-available, **not** open source.
Commercial shipping is explicitly what it's for.

| | |
| --- | --- |
| 💰 **Free tier** | below **100,000 monthly active devices**, per platform, per model |
| 📈 **Above that** | commercial licence needed — licensing@desertant.com |
| 🖥 **iOS + macOS** | counted **separately** — 100k each |
| ♾️ **Term** | perpetual, doesn't expire |
| ⚖️ **Law** | Netherlands / Amsterdam courts |

---

## 📦 What's in the box

| | |
| --- | --- |
| 🖥 **macOS** | `Mac/Umless.xcodeproj` |
| 📱 **iOS** | `iOS/Umless.xcodeproj` |
| 🧠 **Model** | `Umless/UhmModel.bundle` — [Uhm](https://desertant.com/models/uhm/) by Desert Ant Labs, 45 MB, ships inside the app |
| 🌍 **Languages** | English, 简体中文 |

Two independent Xcode projects. No workspace, no shared package — twelve engine
files are byte-identical copies in both. Edit one, copy it across.

---

## 🚀 Build

```sh
# macOS
xcodebuild -project Mac/Umless.xcodeproj -scheme Umless \
  -destination 'platform=macOS' build

# iOS
xcodebuild -project iOS/Umless.xcodeproj -scheme Umless \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

Swap `build` for `-only-testing:UmlessTests test` to run the suite. ✅

---

## 🎯 What's preserved

| Property | Kept? | How |
| --- | :---: | --- |
| Resolution | ✅ | coded dimensions copied off the source track |
| Frame rate | ✅ | exact rational (`1001/30000`, not `0.0333…`) |
| Rotation | ✅ | carried as track metadata, pixels untouched |
| Colour tags | ✅ | primaries / transfer / matrix copied verbatim |
| Codec | ✅ | H.264 → H.264, HEVC → HEVC, ProRes → ProRes |
| Bit rate | ≈ | targets the source's own, with a floor |

---

## ⚠️ Known sharp edges

- 🧪 **The simulator is not the device.** iOS encodes AAC in hardware on real
  hardware and in software on the simulator; they accept different PCM input.
  A green test suite is not proof an export works in your hand.
- 📁 **The model must stay a `.bundle`.** A bare `.mlmodel` gets compiled and
  renamed by Xcode, breaking the filename lookup.
- 👯 **Two copies of the engine.** `diff -r Mac/Umless iOS/Umless` before
  calling any engine change done.
