//
//  ExportBar.swift
//  Umless
//

import SwiftUI

/// The bottom bar: what the edit will do, the export button, and — once a file
/// exists — where to put it.
///
/// On iOS the export lands in a temporary file first. There is no save panel to
/// pick a destination up front, so the file is written, copied into Photos on
/// its own, and left available to the share sheet.
struct ExportBar: View {
    @Bindable var model: AppModel

    @State private var saveState = SaveState.idle
    @State private var isConfirmingSave = false

    private enum SaveState: Equatable {
        case idle, saving, saved, failed
    }

    var body: some View {
        VStack(spacing: 8) {
            summary

            if let exported = model.exportedURL {
                HStack(spacing: 10) {
                    Button {
                        Task { await saveToPhotos(exported) }
                    } label: {
                        Label { Text(saveLabel) } icon: { saveIcon }
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    // The save runs itself the moment the export lands, so this
                    // is a status line most of the time. It only becomes a
                    // button again if that save failed and is worth retrying.
                    .disabled(saveState != .failed)

                    ShareLink(item: exported) {
                        Image(systemName: "square.and.arrow.up")
                            .frame(height: 22)
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityLabel(loc("Share…"))
                }
            } else {
                Button {
                    export()
                } label: {
                    Label(loc("Export Video"), systemImage: "scissors")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.plan.isEmpty)
            }
        }
        .sheet(isPresented: $isConfirmingSave) {
            SavedToPhotosSheet()
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
                // A sheet is presented by the window, outside the scene the
                // theme is applied to, so it has to be applied again here.
                .preferredColorScheme(Appearance.shared.theme.colorScheme)
        }
        .onChange(of: model.exportedURL) { _, url in
            guard let url else { saveState = .idle; return }
            // Keeping the result is the point of pressing Export; making the
            // user ask for it a second time afterwards is just an extra tap.
            saveState = .saving
            Task { await saveToPhotos(url) }
        }
    }

    private var saveLabel: String {
        switch saveState {
        case .idle, .failed: loc("Save to Photos")
        case .saving: loc("Saving…")
        case .saved: loc("Saved to Photos")
        }
    }

    @ViewBuilder private var saveIcon: some View {
        switch saveState {
        case .saving: ProgressView().controlSize(.mini)
        case .saved: Image(systemName: "checkmark.circle.fill")
        case .idle, .failed: Image(systemName: "square.and.arrow.down")
        }
    }

    private var summary: some View {
        let plan = model.plan
        let cuts = plan.removals.count
        return HStack(spacing: 6) {
            Text(cuts == 1 ? loc("1 cut") : String(format: loc("%d cuts"), cuts))
                .fontWeight(.semibold)
            Text("−\(plan.removedDuration.shortDuration)")
                .foregroundStyle(.orange)
            Spacer()
            Text(String(format: loc("New length %1$@, still %2$@."),
                        plan.outputDuration.shortDuration, sizeAndRate))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .font(.footnote.monospacedDigit())
    }

    private var sizeAndRate: String {
        guard let source = model.source else { return "" }
        return "\(Int(source.displaySize.width))×\(Int(source.displaySize.height)) · "
            + String(format: "%.4g fps", source.frameRate)
    }

    private func export() {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(model.suggestedFilename)
        // Get the permission prompt out of the way now, while the user is still
        // looking at the button they pressed. The save itself happens when the
        // export lands, which on a long video is minutes away — a system alert
        // arriving out of nowhere then is a worse thing to be handed.
        Task { await VideoLibrary.requestAddAccess() }
        model.export(to: destination)
    }

    private func saveToPhotos(_ url: URL) async {
        saveState = .saving
        do {
            try await VideoLibrary.save(url)
            saveState = .saved
            isConfirmingSave = true
        } catch {
            saveState = .failed
            model.errorMessage = error.localizedDescription
        }
    }
}

/// Confirms the save once it lands.
///
/// Worth interrupting for: the file goes somewhere the user cannot see from
/// this screen, so without a word from the app there is nothing to tell them
/// it arrived. A sheet rather than an alert — an alert has no room for the
/// mark, and the mark is the part that reads before the sentence does.
private struct SavedToPhotosSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var landed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 62))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, options: .nonRepeating, value: landed)
                .padding(.bottom, 18)

            Text(loc("Saved to Photos"))
                .font(.title2.weight(.semibold))
                .padding(.bottom, 6)

            Text(loc("Your video is in Recents, at the original resolution and frame rate."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)

            Spacer(minLength: 16)

            Button(loc("Done")) { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.bottom, 10)
        }
        .padding(.top, 26)
        .sensoryFeedback(.success, trigger: landed)
        .onAppear { landed = true }
    }
}
