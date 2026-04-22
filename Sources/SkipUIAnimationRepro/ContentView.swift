import Foundation
import Observation
import SwiftUI

/// The top-level repro screen for the Android animation investigation.
struct ContentView: View {
    @State var model = ReproModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReproInstructionsCard()

            //ReproControlsCard(model: model)

            GeometryReader { proxy in
                ReproStageView(
                    model: model,
                    size: nativeSize(width: proxy.size.width, height: proxy.size.height)
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .background(Color(red: 0.06, green: 0.08, blue: 0.12))
    }

    /// Converts `GeometryProxy` size values into Foundation geometry for the repro model.
    private func nativeSize(width: Foundation.CGFloat, height: Foundation.CGFloat) -> Foundation.CGSize {
        Foundation.CGSize(width: width, height: height)
    }
}

/// Shared transition state for the repro scene.
@Observable final class ReproModel {
    static let greenAccent = Color(red: 0.24, green: 0.98, blue: 0.45)
    static let redAccent = Color.red

    struct RedTileState {
        var frame: Foundation.CGRect
        var cornerRadius: Foundation.CGFloat

        static let inactive = RedTileState(
            frame: Foundation.CGRect(x: 0, y: 0, width: 1, height: 1),
            cornerRadius: 0
        )
    }

    var animateGreenTileFade = true
    var animateRedTileMotion = false

    var browserOpacity = 1.0
    var collectionOpacity = 0.0
    var greenOpacity = 1.0
    var redOpacity = 0.0
    var redTileState = RedTileState.inactive
    var isRunning = false
    var runCount = 0
    var stageSize = Foundation.CGSize.zero

    /// Restores the scene to the browser state before a new test run.
    func prepareStage(size: Foundation.CGSize) {
        stageSize = size
        browserOpacity = 1
        collectionOpacity = 0
        greenOpacity = 1
        redOpacity = 0
        redTileState = .inactive
        isRunning = false
    }

    /// Restores the stage so the scope-creep animation can be rerun from the same start state.
    func resetStage() {
        prepareStage(size: stageSize)
    }

    /// Runs the browser-to-collection transition with the same broad animation wiring
    /// that previously caused Android to animate the fullscreen start frame.
    @MainActor
    func runRepro() {
        guard !isRunning else {
            return
        }

        let fullscreenFrame = ReproLayout.fullscreenFrame(in: stageSize)
        let targetFrame = ReproLayout.targetTileFrame(in: stageSize)

        prepareStage(size: stageSize)
        isRunning = true
        runCount += 1

        redOpacity = 1
        redTileState = RedTileState(
            frame: fullscreenFrame,
            cornerRadius: ReproLayout.fullscreenCornerRadius
        )

        if animateGreenTileFade {
            withAnimation(.linear(duration: ReproLayout.greenFadeDuration)) {
                greenOpacity = 0
            }
        } else {
            greenOpacity = 0
        }

        /* Hero Animation - we don't actually need to to animate to reproduce the problem */
        /*Task { @MainActor in
            try? await Task.sleep(nanoseconds: ReproLayout.initialFrameHoldNanoseconds)

            withAnimation(.easeInOut(duration: ReproLayout.heroDuration)) {
                redTileState.frame = targetFrame
                redTileState.cornerRadius = ReproLayout.tileCornerRadius
                browserOpacity = 0
                collectionOpacity = 1
            }

            try? await Task.sleep(nanoseconds: ReproLayout.redFadeDelayNanoseconds)

            withAnimation(.linear(duration: ReproLayout.redFadeDuration)) {
                redOpacity = 0
            }

            try? await Task.sleep(nanoseconds: ReproLayout.redFadeDurationNanoseconds)

            redTileState = .inactive
            isRunning = false
        }*/
    }
}

/// Visual constants and geometry helpers for the repro scene.
enum ReproLayout {
    static let stagePadding = 18.0
    static let tileSpacing = 16.0
    static let tileCornerRadius = 28.0
    static let fullscreenCornerRadius = 0.0

    static let greenFadeDuration = 0.5
    static let redFadeDuration = 2.0
  
    //static let heroDuration = 1.0
    //static let initialFrameHoldNanoseconds: UInt64 = 400_000_000
    //static let redFadeDelayNanoseconds: UInt64 = 1_500_000_000
    //static let redFadeDurationNanoseconds: UInt64 = 1000_000_000

    /// Returns the starting frame for the fullscreen browser snapshot.
    static func fullscreenFrame(in size: Foundation.CGSize) -> Foundation.CGRect {
        Foundation.CGRect(origin: .zero, size: size)
    }

    /// Returns the target tile frame in local stage coordinates.
    static func targetTileFrame(in size: Foundation.CGSize) -> Foundation.CGRect {
        let tileWidth = max(140, (size.width - (stagePadding * 2) - tileSpacing) / 2)
        let tileHeight = tileWidth * 1.02
        let originX = stagePadding + tileWidth + tileSpacing
        let originY = stagePadding + 12
        return Foundation.CGRect(x: originX, y: originY, width: tileWidth, height: tileHeight)
    }

    /// Returns the frame for a tile at the given zero-based index.
    static func tileFrame(index: Int, in size: Foundation.CGSize) -> Foundation.CGRect {
        let tileWidth = max(140, (size.width - (stagePadding * 2) - tileSpacing) / 2)
        let tileHeight = tileWidth * 1.02
        let row = index / 2
        let column = index % 2
        let originX = stagePadding + Double(column) * (tileWidth + tileSpacing)
        let originY = stagePadding + 12 + Double(row) * (tileHeight + tileSpacing)
        return Foundation.CGRect(x: originX, y: originY, width: tileWidth, height: tileHeight)
    }
}

/// The top explanation block that tells the user what to look for.
struct ReproInstructionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SkipUI Android Animation Repro")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("Animation Scope Creep: .withAnimation() bleeds into global scope on Android, affecting all UIComponents with updated states")
                .foregroundStyle(.white.opacity(0.88))

            VStack(alignment: .leading, spacing: 6) {
              Text("Observe correct behavior on iOS, incorrect behavior on Android")
                ReproStatusLine(
                    title: "Correct",
                    detail: "Red tile instantly full size (no motion)"
                )
                ReproStatusLine(
                    title: "Incorrect",
                    detail: "Red tile motions outside animated scope"
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

/// The control card exposes the two switches that were found to affect the bug.
struct ReproControlsCard: View {
    @Bindable var model: ReproModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Animate green tile (fade)", isOn: $model.animateGreenTileFade)
                .tint(ReproModel.greenAccent)
                .foregroundStyle(ReproModel.greenAccent)

            Toggle("Animate red tile (motion)", isOn: $model.animateRedTileMotion)
                .tint(ReproModel.redAccent)
                .foregroundStyle(ReproModel.redAccent)

            Text("Control case: disable both switches. On Android, the bug is present if enabling either switch makes the red tile animate in.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

/// A single labeled line in the explanation card.
struct ReproStatusLine: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title + ":")
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
            Text(detail)
                .foregroundStyle(.white.opacity(0.84))
        }
        .font(.footnote)
    }
}

/// The stage that shows the browser scene, collection scene, and moving red tile.
struct ReproStageView: View {
    let model: ReproModel
    let size: Foundation.CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            GreenStageTile(greenOpacity: model.greenOpacity)
                .opacity(model.browserOpacity)

            CollectionStage()
                .opacity(model.collectionOpacity)

            redTileLayer

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button(model.isRunning ? "Updating…" : "Update State") {
                        model.runRepro()
                    }
                    .disabled(model.isRunning)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    Button("Reset") {
                        model.resetStage()
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)

                    Text("Run \(model.runCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                }

                Text("Watch the red tile at the start of the run. It should begin full size, not grow in from the top-left.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.40))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(16)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .task(id: stageKey) {
            model.prepareStage(size: size)
        }
    }

    private var stageKey: String {
        "\(Int(size.width))x\(Int(size.height))"
    }

    @ViewBuilder
    private var redTileLayer: some View {
        let redTile = RedTileView(
            redTileState: model.redTileState,
            redOpacity: model.redOpacity
        )

        /*if model.animateRedTileMotion {
            redTile.animation(.linear(duration: ReproLayout.redFadeDuration), value: model.redOpacity)
        } else {
            redTile
        }*/
        redTile
    }
}

/// The single green tile that stands in for sibling UI outside the red tile branch.
struct GreenStageTile: View {
    let greenOpacity: Double

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(ReproModel.greenAccent)
                .frame(width: 168, height: 168)
                .padding(24)
                .opacity(greenOpacity)
        }
    }
}

/// The collection scene that the red tile animates into.
struct CollectionStage: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(0..<6, id: \.self) { index in
                    let frame = ReproLayout.tileFrame(
                        index: index,
                        in: Foundation.CGSize(width: proxy.size.width, height: proxy.size.height)
                    )
                    RoundedRectangle(cornerRadius: ReproLayout.tileCornerRadius)
                        .fill(index == 1 ? Color.white.opacity(0.10) : Color.white.opacity(0.06))
                        .frame(width: frame.width, height: frame.height)
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(index == 1 ? "TARGET TILE" : "TAB \(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.72))
                                Text(index == 1 ? "The browser snapshot should shrink into this tile." : "Background reference tile")
                                    .font(.footnote.weight(index == 1 ? .semibold : .regular))
                                    .foregroundStyle(.white.opacity(0.86))
                            }
                            .padding(16)
                        }
                        .overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(Color.black.opacity(0.42))
                                .frame(width: 46, height: 46)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .foregroundStyle(.white)
                                )
                                .padding(14)
                        }
                        .offset(x: frame.minX, y: frame.minY)
                }
            }
        }
    }
}

/// The moving red tile so the start geometry is obvious.
struct RedTileView: View {
    let redTileState: ReproModel.RedTileState
    let redOpacity: Double

    var body: some View {
        let frame = redTileState.frame

        RoundedRectangle(cornerRadius: redTileState.cornerRadius)
            .fill(Color.red.opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: redTileState.cornerRadius)
                    .stroke(Color.red, lineWidth: 6)
            )
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SNAPSHOT")
                        .font(.caption.weight(.bold))
                    Text("x: \(Int(frame.minX))")
                    Text("y: \(Int(frame.minY))")
                    Text("w: \(Int(frame.width))")
                    Text("h: \(Int(frame.height))")
                }
                .font(.caption)
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.red.opacity(0.34))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(12)
            }
            .frame(width: max(frame.width, 1), height: max(frame.height, 1))
            .opacity(redOpacity)
            .offset(x: frame.minX, y: frame.minY)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
