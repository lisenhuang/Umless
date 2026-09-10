//
//  ContentView.swift
//  Umless
//

import AVFoundation
import PhotosUI
import SwiftUI
import Uhm

struct ContentView: View {
    @State private var model = AppModel()
    @State private var pickedItem: PhotosPickerItem?
    @State private var isImportingFile = false
    @State private var isShowingSettings = false
    @State private var isImportingFromPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if model.source == nil {
                    WelcomeView(pickedItem: $pickedItem, onBrowseFiles: { isImportingFile = true })
                } else {
                    editor
                }
            }
            .navigationTitle("Umless")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.source != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(loc("Close")) { model.reset() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        PhotosPicker(selection: $pickedItem, matching: .videos) {
                            Image(systemName: "photo.badge.plus")
                        }
                        .accessibilityLabel(loc("Open Video"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isShowingSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel(loc("Settings"))
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
                .preferredColorScheme(Appearance.shared.theme.colorScheme)
        }
        .fileImporter(isPresented: $isImportingFile,
                      allowedContentTypes: AppModel.readableTypes) { result in
            if case .success(let url) = result { model.open(url: url) }
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
        .overlay {
            if model.stage.isBusy || isImportingFromPicker {
                ProgressOverlay(stage: model.stage,
                                isImporting: isImportingFromPicker,
                                onCancel: model.cancelWork)
            }
        }
        .alert(loc("Something went wrong"),
               isPresented: Binding(get: { model.errorMessage != nil },
                                    set: { if !$0 { model.errorMessage = nil } })) {
            Button(loc("OK"), role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    /// Copies the picked video out of Photos, then hands the URL to the model.
    private func load(_ item: PhotosPickerItem) async {
        isImportingFromPicker = true
        defer { isImportingFromPicker = false; pickedItem = nil }
        do {
            guard let movie = try await item.loadTransferable(type: PickedMovie.self) else {
                model.errorMessage = loc("That video couldn’t be loaded from your library.")
                return
            }
            model.open(url: movie.url)
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }

    // MARK: Editor

    private var editor: some View {
        VStack(spacing: 0) {
            PlayerLayerView(player: model.player.player)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(.black)

            transport
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 10)

            Divider()
            controls
            Divider()

            FillerListView(model: model)
                .frame(maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { exportBar }
    }

    private var transport: some View {
        VStack(spacing: 4) {
            TimelineBar(
                player: model.player,
                markers: model.player.markers,
                disabledIDs: model.disabledIDs,
                removals: model.previewsCut ? [] : model.plan.removals,
                onScrub: { model.player.seek(to: $0) },
                onMarkerTap: { model.player.playFrom($0.start) })

            HStack(spacing: 18) {
                Button { jump(-1) } label: { Image(systemName: "chevron.left.2") }
                    .disabled(model.player.markers.isEmpty)
                Button {
                    model.player.togglePlayback()
                } label: {
                    Image(systemName: model.player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 22)
                }
                Button { jump(1) } label: { Image(systemName: "chevron.right.2") }
                    .disabled(model.player.markers.isEmpty)

                TimeReadout(player: model.player)

                Spacer()

                Toggle(loc("Preview the cut"), isOn: Bindable(model).previewsCut)
                    .toggleStyle(.button)
                    .font(.footnote)
                    .disabled(model.plan.isEmpty)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker(loc("Sensitivity"), selection: Bindable(model).sensitivity) {
                ForEach([Uhm.Bias.precision, .balanced, .recall], id: \.self) { bias in
                    Text(bias.displayName).tag(bias)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text(loc("Trim around each cut"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Slider(value: Bindable(model).padding, in: 0...0.25)
                Text(String(format: loc("%.0f ms"), model.padding * 1000))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 62, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// Pinned below the list rather than carried inside it: the summary and the
    /// export button stay reachable however far the list is scrolled.
    ///
    /// `safeAreaInset` holds it out of the scrolling content while still
    /// letting rows travel underneath. The divider is what makes that read
    /// correctly — without one, a half-scrolled row is simply sliced off at the
    /// bar's edge and the result looks like clipped content rather than a fixed
    /// footer. The background is drawn separately so it can run past the home
    /// indicator; left to the bar's own bounds it stops short of the screen
    /// edge and leaves a strip of list showing beneath.
    private var exportBar: some View {
        VStack(spacing: 0) {
            Divider()
            ExportBar(model: model)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)
        }
        .background {
            Rectangle()
                .fill(.bar)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    /// Skips to the next/previous marker so every cut can be auditioned without
    /// aiming at a few pixels of scrubber.
    private func jump(_ direction: Int) {
        let now = model.player.currentTime
        let markers = model.player.markers
        let target = direction > 0
            ? markers.first { $0.start > now + 0.05 }
            : markers.last { $0.start < now - 0.4 }
        if let target { model.player.playFrom(target.start) }
    }
}

/// The clock, split out so the playhead ticking doesn't invalidate the whole
/// transport row — and with it the timeline — thirty times a second.
private struct TimeReadout: View {
    let player: PlayerController

    var body: some View {
        Text("\(player.currentTime.timecode) / \(player.duration.timecode)")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
    }
}

// MARK: - Welcome

private struct WelcomeView: View {
    @Binding var pickedItem: PhotosPickerItem?
    let onBrowseFiles: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "waveform.badge.minus")
                .font(.system(size: 62, weight: .light))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text(loc("Cut the ums out"))
                    .font(.title2.weight(.semibold))
                Text(loc("Umless listens for “um”, “uh” and “hmm”, shows you each one, and exports a cut at the original resolution and frame rate."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 10) {
                PhotosPicker(selection: $pickedItem, matching: .videos) {
                    Label(loc("Choose Video"), systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: onBrowseFiles) {
                    Label(loc("Browse Files"), systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Text(loc("Runs entirely on your device — nothing is uploaded."))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Progress

private struct ProgressOverlay: View {
    let stage: AppModel.Stage
    let isImporting: Bool
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Rectangle().fill(.black.opacity(0.4)).ignoresSafeArea()
            VStack(spacing: 14) {
                Text(title).font(.headline).multilineTextAlignment(.center)
                if let fraction {
                    ProgressView(value: fraction).progressViewStyle(.linear).frame(width: 220)
                } else {
                    ProgressView().progressViewStyle(.linear).frame(width: 220)
                }
                if let note {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                if !isImporting {
                    Button(loc("Cancel"), role: .cancel, action: onCancel)
                        .controlSize(.small)
                }
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
            .padding(40)
        }
    }

    private var title: String {
        if isImporting { return loc("Loading the video…") }
        return switch stage {
        case .openingVideo: loc("Reading the video…")
        case .extractingAudio: loc("Pulling out the audio…")
        case .analyzing: loc("Listening for fillers…")
        case .exporting: loc("Exporting your video…")
        case .empty, .reviewing: ""
        }
    }

    private var note: String? {
        switch stage {
        case .analyzing: loc("Running on this device’s Neural Engine.")
        case .exporting: loc("Re-encoding at the source resolution and frame rate.")
        default: nil
        }
    }

    private var fraction: Double? {
        if isImporting { return nil }
        return switch stage {
        case .extractingAudio(let f), .analyzing(let f), .exporting(let f): f
        case .openingVideo, .empty, .reviewing: nil
        }
    }
}

#Preview {
    ContentView()
}
