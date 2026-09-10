//
//  Sidebar.swift
//  Umless
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers
import Uhm

/// Source info, the two tuning controls, the reviewable list, and export.
struct Sidebar: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            sourceHeader
            Divider()
            controls
            Divider()
            FillerListView(model: model)
                .frame(maxHeight: .infinity)
            Divider()
            exportFooter
        }
        .background(.background)
    }

    // MARK: Source

    private var sourceHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(model.source?.url.lastPathComponent ?? "")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(model.source?.url.path ?? "")
            Text(model.source?.formatSummary ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: Controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Picker(loc("Sensitivity"), selection: $model.sensitivity) {
                    ForEach([Uhm.Bias.precision, .balanced, .recall], id: \.self) { bias in
                        Text(bias.displayName).tag(bias)
                    }
                }
                .pickerStyle(.menu)
                Text(model.sensitivity.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(loc("Trim around each cut"))
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: loc("%.0f ms"), model.padding * 1000))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $model.padding, in: 0...0.25)
                    .controlSize(.small)
                Text(loc("Takes the breath either side of the filler with it."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: Export

    private var exportFooter: some View {
        VStack(alignment: .leading, spacing: 9) {
            summary

            Button {
                presentSavePanel()
            } label: {
                Label(loc("Export Video…"), systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .disabled(model.plan.isEmpty)
            .help(model.plan.isEmpty
                  ? loc("Nothing is selected to cut")
                  : loc("Write a new file with the selected cuts removed"))

            if let exported = model.exportedURL {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(loc("Exported")).font(.caption)
                    Button(loc("Show in Finder")) {
                        NSWorkspace.shared.activateFileViewerSelecting([exported])
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var summary: some View {
        let plan = model.plan
        let cuts = plan.removals.count
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(cuts == 1 ? loc("1 cut") : String(format: loc("%d cuts"), cuts))
                Spacer()
                Text("−\(plan.removedDuration.shortDuration)")
                    .foregroundStyle(.orange)
            }
            .font(.subheadline.weight(.medium).monospacedDigit())

            Text(String(format: loc("New length %1$@, still %2$@."),
                        plan.outputDuration.shortDuration, sizeAndRate))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var sizeAndRate: String {
        guard let source = model.source else { return "format" }
        return "\(Int(source.displaySize.width))×\(Int(source.displaySize.height)) at "
            + String(format: "%.4g fps", source.frameRate)
    }

    /// `NSSavePanel` rather than `.fileExporter`: the destination has to be
    /// chosen before the encode starts, and the panel is what grants the
    /// sandbox write access to it.
    private func presentSavePanel() {
        guard let source = model.source else { return }
        let panel = NSSavePanel()
        panel.title = loc("Save Exported Video")
        panel.nameFieldStringValue = model.suggestedFilename
        panel.canCreateDirectories = true
        panel.directoryURL = source.url.deletingLastPathComponent()
        if let type = UTType(filenameExtension: source.url.pathExtension) {
            panel.allowedContentTypes = [type]
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        model.export(to: url)
    }
}
