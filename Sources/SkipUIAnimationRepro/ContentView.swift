import Observation
import SwiftUI

/// The top-level repro screen for the Android animation investigation.
struct ContentView: View {
    @State var model = ReproModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReproInstructionsCard()

            ReproStageView(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .background(Color(red: 0.06, green: 0.08, blue: 0.12))
    }
}

/// Shared fade state for the two-tile repro scene.
@Observable final class ReproModel {
    static let greenAccent = Color(red: 0.24, green: 0.98, blue: 0.45)
    static let redAccent = Color.red

    var greenOpacity = 1.0
    var redOpacity = 1.0
    var isRunning = false
    var runCount = 0

    /// Restores the stage to the fully visible baseline state.
    func prepareStage() {
        greenOpacity = 1
        redOpacity = 1
        isRunning = false
    }

    /// Restores the stage so the same state change can be rerun.
    func resetStage() {
        prepareStage()
    }

    /// Updates both tiles to opacity zero, but scopes animation only to the green write.
    @MainActor
    func runRepro() {
        guard !isRunning else {
            return
        }

        prepareStage()
        isRunning = true
        runCount += 1

        redOpacity = 0

        withAnimation(.linear(duration: ReproLayout.greenFadeDuration)) {
            greenOpacity = 0
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: ReproLayout.greenFadeDurationNanoseconds)
            isRunning = false
        }
    }
}

/// Visual constants for the simplified two-tile repro.
enum ReproLayout {
    static let tileSize = 168.0
    static let tileCornerRadius = 28.0
    static let tileSpacing = 36.0
    static let greenFadeDuration = 1.5
    static let greenFadeDurationNanoseconds: UInt64 = 1500_000_000
}

/// The explanation block that tells the user what to look for.
struct ReproInstructionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SkipUI Android Animation Repro")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("Animation scope creep: only `greenOpacity` is wrapped in `withAnimation`, but Android also animates the red tile.")
                .foregroundStyle(.white.opacity(0.88))

            VStack(alignment: .leading, spacing: 6) {
                Text("Observe correct behavior on iOS, incorrect behavior on Android")
                    .foregroundStyle(.white.opacity(0.84))

                ReproStatusLine(
                    title: "Correct",
                    detail: "Green fades out. Red disappears instantly."
                )
                ReproStatusLine(
                    title: "Incorrect",
                    detail: "Red fades out too, even though its state write is outside `withAnimation`."
                )
            }
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

/// The simplified stage with two matching tiles and a small control row.
struct ReproStageView: View {
    let model: ReproModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: ReproLayout.tileSpacing) {
                ReproTileColumn(
                    title: "Green",
                    accent: ReproModel.greenAccent,
                    opacity: model.greenOpacity
                )

                ReproTileColumn(
                    title: "Red",
                    accent: ReproModel.redAccent,
                    opacity: model.redOpacity
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button(model.isRunning ? "Animating…" : "Animate") {
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

                Text("Both tiles update to opacity 0. Only the green write is scoped in `withAnimation`.")
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
        .task {
            model.prepareStage()
        }
    }
}

/// A tile and label pair used for both the green and red branches.
struct ReproTileColumn: View {
    let title: String
    let accent: Color
    let opacity: Double

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: ReproLayout.tileCornerRadius, style: .continuous)
                .fill(accent)
                .frame(width: ReproLayout.tileSize, height: ReproLayout.tileSize)
                .opacity(opacity)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)
        }
    }
}
