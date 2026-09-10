//
//  FillerListView.swift
//  Umless
//

import SwiftUI

/// The reviewable list of everything the model heard.
struct FillerListView: View {
    @Bindable var model: AppModel

    var body: some View {
        let fillers = model.visibleFillers
        VStack(spacing: 0) {
            header(count: fillers.count)
            Divider()
            if fillers.isEmpty {
                ContentUnavailableView(
                    loc("No fillers at this setting"),
                    systemImage: "waveform",
                    description: Text(loc("Try “Catch everything” to widen the net.")))
                .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(fillers) { filler in
                        row(filler)
                            .id(filler.id)
                            .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                    }
                    .listStyle(.inset)
                    .onChange(of: model.player.activeMarkerID) { _, id in
                        guard let id else { return }
                        withAnimation { proxy.scrollTo(id, anchor: .center) }
                    }
                }
            }
        }
    }

    private func header(count: Int) -> some View {
        HStack {
            Text(String(format: loc("%d found"), count))
                .font(.subheadline.weight(.medium))
            Spacer()
            Button(loc("All")) { model.setAllEnabled(true) }
            Button(loc("None")) { model.setAllEnabled(false) }
        }
        .buttonStyle(.link)
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func row(_ filler: Filler) -> some View {
        let isPlaying = model.player.activeMarkerID == filler.id
        return HStack(spacing: 9) {
            Toggle("", isOn: Binding(
                get: { model.isEnabled(filler) },
                set: { model.setEnabled($0, for: filler) }))
            .labelsHidden()
            .toggleStyle(.checkbox)
            .help(model.isEnabled(filler) ? loc("This one will be cut") : loc("This one will be kept"))

            Button {
                model.player.playFrom(filler.start)
            } label: {
                HStack(spacing: 8) {
                    Text("“\(filler.label)”")
                        .font(.body.weight(.medium))
                        .foregroundStyle(model.isEnabled(filler) ? .primary : .secondary)
                    Spacer(minLength: 0)
                    Text(filler.start.timecode)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    ConfidenceDots(confidence: filler.confidence)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(String(format: loc("Play from %@"), filler.start.timecode))
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(isPlaying ? Color.orange.opacity(0.18) : .clear)
        }
    }
}

/// Three dots for how sure the model is — quicker to scan down a list than a
/// percentage, and the exact number isn't actionable.
private struct ConfidenceDots: View {
    let confidence: Double

    private var filled: Int {
        switch confidence {
        case ..<0.65: 1
        case ..<0.8: 2
        default: 3
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i < filled ? Color.secondary : Color.secondary.opacity(0.22))
                    .frame(width: 4, height: 4)
            }
        }
        .help(String(format: loc("Confidence %.0f%%"), confidence * 100))
    }
}
