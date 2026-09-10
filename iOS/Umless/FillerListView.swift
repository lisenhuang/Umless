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
                            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                    }
                    .listStyle(.plain)
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
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button(loc("All")) { model.setAllEnabled(true) }
            Button(loc("None")) { model.setAllEnabled(false) }
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func row(_ filler: Filler) -> some View {
        let isPlaying = model.player.activeMarkerID == filler.id
        let isEnabled = model.isEnabled(filler)
        return HStack(spacing: 12) {
            // A tap target rather than a checkbox: there is no checkbox style
            // on iOS, and a 44pt circle is the right size for a thumb.
            Button {
                model.setEnabled(!isEnabled, for: filler)
            } label: {
                Image(systemName: isEnabled ? "scissors.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isEnabled ? Color.orange : Color.secondary.opacity(0.5))
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isEnabled ? loc("This one will be cut") : loc("This one will be kept"))

            Button {
                model.player.playFrom(filler.start)
            } label: {
                HStack(spacing: 10) {
                    Text("“\(filler.label)”")
                        .font(.body.weight(.medium))
                        .foregroundStyle(isEnabled ? .primary : .secondary)
                    Spacer(minLength: 0)
                    Text(filler.start.timecode)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                    ConfidenceDots(confidence: filler.confidence)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(format: loc("Play from %@"), filler.start.timecode))
        }
        .padding(.vertical, 4)
        .listRowBackground(isPlaying ? Color.orange.opacity(0.14) : Color.clear)
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
        .accessibilityLabel(String(format: loc("Confidence %.0f%%"), confidence * 100))
    }
}
