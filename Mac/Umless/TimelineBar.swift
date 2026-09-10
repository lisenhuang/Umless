//
//  TimelineBar.swift
//  Umless
//
//  The duration bar: every filler marked in place, click one to play from it.
//

import SwiftUI

/// A scrubber that doubles as a map of the fillers.
///
/// Split into two layers on purpose. The marker layer is expensive — a whole
/// video's worth of fillers — but only changes when the detection or the
/// selection does, so it never sees `currentTime`. The playhead layer is two
/// shapes and is the only thing that redraws as the video plays.
///
/// Hit testing lives here rather than on per-marker buttons: one gesture has to
/// serve both scrubbing and marker clicks, and nested buttons would swallow the
/// scrub. A click that never moved counts as a marker hit when it lands within
/// `hitSlop` of one, and as a plain seek otherwise.
struct TimelineBar: View {
    let player: PlayerController
    /// Every filler at the current sensitivity, whether or not it will be cut.
    let markers: [Filler]
    /// The ones the user unticked — drawn hollow, since they stay in the video.
    let disabledIDs: Set<Filler.ID>
    /// Spans that will actually be removed, padding included.
    let removals: [ClosedRange<Double>]
    var onScrub: (Double) -> Void
    var onMarkerTap: (Filler) -> Void

    /// Half-width of a marker's clickable area. Fillers run a few hundred
    /// milliseconds, which is sub-pixel in a long video, so the target is grown
    /// well past the drawn width.
    static let hitSlop: CGFloat = 7
    static let minMarkerWidth: CGFloat = 4
    private let barHeight: CGFloat = 30
    private let tooltipHeight: CGFloat = 26

    @State private var dragStartX: CGFloat?
    @State private var isDragging = false
    @State private var hovered: Filler?

    var body: some View {
        let duration = player.duration
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .topLeading) {
                if let hovered {
                    tooltip(for: hovered, width: width)
                }

                ZStack(alignment: .leading) {
                    MarkerLayer(duration: duration, markers: markers,
                                disabledIDs: disabledIDs, removals: removals,
                                hoveredID: hovered?.id, activeID: player.activeMarkerID)
                        .equatable()
                    PlayheadLayer(player: player)
                }
                .frame(height: barHeight)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.quaternary, lineWidth: 1))
                .offset(y: tooltipHeight)
            }
            .frame(width: width, height: barHeight + tooltipHeight, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(scrubGesture(width: width, duration: duration))
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    let hit = Self.marker(near: point.x, in: markers, width: width, duration: duration)
                    if hit?.id != hovered?.id { hovered = hit }
                case .ended:
                    hovered = nil
                }
            }
        }
        .frame(height: barHeight + tooltipHeight)
    }

    // MARK: Tooltip

    private func tooltip(for marker: Filler, width: CGFloat) -> some View {
        let centre = Self.x(for: (marker.start + marker.end) / 2, width: width, duration: player.duration)
        return Text("“\(marker.label)” · \(marker.start.timecode)")
            .font(.caption.monospacedDigit())
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.quaternary))
            .fixedSize()
            // Nudged back inside the bar so a marker at either end stays readable.
            .modifier(CentredWithinBounds(centre: centre, bounds: width))
            .allowsHitTesting(false)
    }

    // MARK: Geometry

    static func x(for time: Double, width: CGFloat, duration: Double) -> CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(min(max(0, time / duration), 1)) * width
    }

    private static func time(atX px: CGFloat, width: CGFloat, duration: Double) -> Double {
        guard width > 0 else { return 0 }
        return min(max(0, Double(px / width) * duration), duration)
    }

    /// The filler whose drawn extent (grown by `hitSlop`) contains `px`,
    /// preferring the closest when two overlap.
    static func marker(near px: CGFloat, in markers: [Filler],
                       width: CGFloat, duration: Double) -> Filler? {
        markers
            .map { marker -> (Filler, CGFloat) in
                let start = x(for: marker.start, width: width, duration: duration)
                let end = max(start + minMarkerWidth, x(for: marker.end, width: width, duration: duration))
                let distance: CGFloat = px < start ? start - px : (px > end ? px - end : 0)
                return (marker, distance)
            }
            .filter { $0.1 <= hitSlop }
            .min { $0.1 < $1.1 }?.0
    }

    // MARK: Gesture

    private func scrubGesture(width: CGFloat, duration: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStartX == nil { dragStartX = value.location.x }
                if let start = dragStartX, abs(value.location.x - start) > 3 { isDragging = true }
                if isDragging { onScrub(Self.time(atX: value.location.x, width: width, duration: duration)) }
            }
            .onEnded { value in
                defer { dragStartX = nil; isDragging = false }
                let hit = Self.marker(near: value.location.x, in: markers, width: width, duration: duration)
                if !isDragging, let hit {
                    onMarkerTap(hit)
                } else {
                    onScrub(Self.time(atX: value.location.x, width: width, duration: duration))
                }
            }
    }
}

// MARK: - Layers

/// Everything that doesn't move while the video plays, drawn in one pass.
///
/// A `Canvas` rather than a `ForEach` of shapes: a long recording can carry
/// hundreds of fillers, and this is one draw instead of hundreds of views.
private struct MarkerLayer: View, Equatable {
    let duration: Double
    let markers: [Filler]
    let disabledIDs: Set<Filler.ID>
    let removals: [ClosedRange<Double>]
    let hoveredID: Filler.ID?
    let activeID: Filler.ID?

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let width = size.width
            let height = size.height
            func x(_ t: Double) -> CGFloat {
                TimelineBar.x(for: t, width: width, duration: duration)
            }

            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.gray.opacity(0.18)))

            // What's being cut, padding included.
            for range in removals {
                let start = x(range.lowerBound)
                let rect = CGRect(x: start, y: 0, width: max(1.5, x(range.upperBound) - start), height: height)
                context.fill(Path(rect), with: .color(.orange.opacity(0.16)))
            }

            // The fillers themselves.
            for marker in markers {
                let start = x(marker.start)
                let w = max(TimelineBar.minMarkerWidth, x(marker.end) - start)
                let rect = CGRect(x: start, y: 4, width: w, height: height - 8)
                let path = Path(roundedRect: rect, cornerRadius: 2)
                let emphasised = marker.id == hoveredID || marker.id == activeID

                if disabledIDs.contains(marker.id) {
                    // Staying in the video: outline only.
                    context.stroke(path, with: .color(.orange.opacity(emphasised ? 0.9 : 0.5)), lineWidth: 1.5)
                } else {
                    context.fill(path, with: .color(.orange.opacity(emphasised ? 1 : 0.85)))
                    if emphasised {
                        context.stroke(path, with: .color(.white.opacity(0.9)), lineWidth: 1.5)
                    }
                }
            }
        }
    }
}

/// The only part that redraws as the video plays.
///
/// Reads `currentTime` itself instead of taking it as a parameter, so
/// observation invalidates this view alone and leaves the marker layer alone.
private struct PlayheadLayer: View {
    let player: PlayerController

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let x = TimelineBar.x(for: player.currentTime, width: width, duration: player.duration)
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.25))
                    .frame(width: max(0, x))
                Capsule()
                    .fill(.primary)
                    .frame(width: 2.5)
                    .shadow(color: .black.opacity(0.35), radius: 1.5)
                    .offset(x: max(0, min(width - 2.5, x - 1.25)))
            }
            .frame(width: width, height: geo.size.height, alignment: .leading)
        }
        .allowsHitTesting(false)
    }
}

/// Centres a fixed-size label on `centre` without letting it hang off either
/// end of `bounds`.
private struct CentredWithinBounds: ViewModifier {
    let centre: CGFloat
    let bounds: CGFloat

    func body(content: Content) -> some View {
        content.alignmentGuide(.leading) { d in
            let half = d.width / 2
            let clamped = min(max(half, centre), max(half, bounds - half))
            return -(clamped - half)
        }
    }
}

nonisolated extension Double {
    /// `m:ss.hh` — hundredths matter here, fillers are a few hundred ms long.
    var timecode: String {
        guard isFinite, self >= 0 else { return "0:00.00" }
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = truncatingRemainder(dividingBy: 60)
        if hours > 0 {
            return String(format: "%d:%02d:%05.2f", hours, minutes, seconds)
        }
        return String(format: "%d:%05.2f", minutes, seconds)
    }

    /// Rounded duration for summaries ("saves 12.4s").
    var shortDuration: String {
        if self < 60 { return String(format: "%.1fs", self) }
        return String(format: "%d:%02d", Int(self) / 60, Int(rounded()) % 60)
    }
}
