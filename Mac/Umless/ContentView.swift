//
//  ContentView.swift
//  Umless
//
//  Created by Eason Smith on 10/09/2026.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers
import Uhm

struct ContentView: View {
    @State private var model = AppModel()
    @State private var isImporting = false
    @State private var isTargetedForDrop = false

    var body: some View {
        Group {
            if model.source == nil {
                DropZone(isTargeted: isTargetedForDrop) { isImporting = true }
            } else {
                editor
            }
        }
        .frame(minWidth: 940, minHeight: 620)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first(where: \.looksLikeVideo) else { return false }
            model.open(url: url)
            return true
        } isTargeted: { isTargetedForDrop = $0 }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: AppModel.readableTypes
        ) { result in
            if case .success(let url) = result { model.open(url: url) }
        }
        .overlay {
            if model.stage.isBusy { ProgressOverlay(stage: model.stage, onCancel: model.cancelWork) }
        }
        .alert(loc("Something went wrong"),
               isPresented: Binding(get: { model.errorMessage != nil },
                                    set: { if !$0 { model.errorMessage = nil } })) {
            Button(loc("OK"), role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    isImporting = true
                } label: {
                    Label(loc("Open Video"), systemImage: "folder")
                }
                .help(loc("Choose a different video"))
            }
            if model.source != nil {
                ToolbarItem(placement: .destructiveAction) {
                    Button(loc("Close"), systemImage: "xmark.circle") { model.reset() }
                        .help(loc("Close this video"))
                }
            }
        }
    }

    // MARK: Editor

    private var editor: some View {
        HSplitView {
            VStack(spacing: 0) {
                PlayerLayerView(player: model.player.player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)

                transport
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 14)
                    .background(.bar)
            }
            .frame(minWidth: 520)

            Sidebar(model: model)
                .frame(minWidth: 300, idealWidth: 340, maxWidth: 460)
        }
    }

    private var transport: some View {
        VStack(spacing: 6) {
            TimelineBar(
                player: model.player,
                markers: model.player.markers,
                disabledIDs: model.disabledIDs,
                removals: model.previewsCut ? [] : model.plan.removals,
                onScrub: { model.player.seek(to: $0) },
                onMarkerTap: { model.player.playFrom($0.start) })

            HStack(spacing: 12) {
                Button {
                    model.player.togglePlayback()
                } label: {
                    Image(systemName: model.player.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 16)
                }
                .keyboardShortcut(.space, modifiers: [])
                .help(model.player.isPlaying ? loc("Pause") : loc("Play"))

                Button { jump(-1) } label: { Image(systemName: "chevron.left.2") }
                    .help(loc("Previous filler"))
                    .disabled(model.player.markers.isEmpty)
                Button { jump(1) } label: { Image(systemName: "chevron.right.2") }
                    .help(loc("Next filler"))
                    .disabled(model.player.markers.isEmpty)

                TimeReadout(player: model.player)

                Spacer()

                Toggle(loc("Preview the cut"), isOn: Bindable(model).previewsCut)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .help(loc("Play the edited version instead of the original"))
                    .disabled(model.plan.isEmpty)
            }
            .buttonStyle(.accessoryBar)
        }
    }

    /// Skips to the next/previous marker so you can audition every cut without
    /// aiming at a 4-pixel target.
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

// MARK: - Drop zone

private struct DropZone: View {
    let isTargeted: Bool
    let onChoose: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "waveform.badge.minus")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 6) {
                Text(loc("Drop a video here"))
                    .font(.title2.weight(.semibold))
                Text(loc("Umless listens for “um”, “uh” and “hmm”, shows you each one,\nand exports a cut at the original resolution and frame rate."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(loc("Choose Video…"), action: onChoose)
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

            Text(loc("Runs entirely on your Mac — nothing is uploaded."))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [9, 7]))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.35))
                .padding(26)
        }
        .animation(.easeOut(duration: 0.15), value: isTargeted)
    }
}

// MARK: - Progress

private struct ProgressOverlay: View {
    let stage: AppModel.Stage
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Rectangle().fill(.black.opacity(0.35)).ignoresSafeArea()
            VStack(spacing: 14) {
                Text(title).font(.headline)
                if let fraction {
                    ProgressView(value: fraction).progressViewStyle(.linear).frame(width: 260)
                } else {
                    ProgressView().progressViewStyle(.linear).frame(width: 260)
                }
                if let note {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
                Button(loc("Cancel"), role: .cancel, action: onCancel)
                    .controlSize(.small)
            }
            .padding(26)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 22)
        }
    }

    private var title: String {
        switch stage {
        case .openingVideo: loc("Reading the video…")
        case .extractingAudio: loc("Pulling out the audio…")
        case .analyzing: loc("Listening for fillers…")
        case .exporting: loc("Exporting your video…")
        case .empty, .reviewing: ""
        }
    }

    private var note: String? {
        switch stage {
        case .analyzing: loc("Running on this Mac’s Neural Engine.")
        case .exporting: loc("Re-encoding at the source resolution and frame rate.")
        default: nil
        }
    }

    private var fraction: Double? {
        switch stage {
        case .extractingAudio(let f), .analyzing(let f), .exporting(let f): f
        case .openingVideo, .empty, .reviewing: nil
        }
    }
}

private extension URL {
    /// A dragged file may not be readable yet, so the declared type is checked
    /// first and the extension is the fallback.
    var looksLikeVideo: Bool {
        if let type = (try? resourceValues(forKeys: [.contentTypeKey]).contentType) {
            return type.conforms(to: .audiovisualContent)
        }
        if let type = UTType(filenameExtension: pathExtension) {
            return type.conforms(to: .audiovisualContent)
        }
        return false
    }
}

#Preview {
    ContentView()
}
