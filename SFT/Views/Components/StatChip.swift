import SwiftUI

struct StatChip: View {
    let title: String
    let value: String
    let tint: Color
    let systemImage: String
    var current: Double = 0
    var goal: Double = 0

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }

    private var hasGoal: Bool { goal > 0 }
    private var isComplete: Bool { hasGoal && progress >= 1.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.mist)

                Spacer()

                if hasGoal {
                    ZStack {
                        Circle()
                            .stroke(tint.opacity(0.18), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                isComplete ? AppTheme.jade : tint,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.5), value: progress)
                    }
                    .frame(width: 26, height: 26)
                }
            }

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(isComplete ? AppTheme.jade : .white)

            if hasGoal {
                Text("of \(goalLabel)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.mist)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 108, alignment: .topLeading)
        .padding(16)
        .background(isComplete ? AppTheme.jade.opacity(0.12) : tint.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isComplete ? AppTheme.jade.opacity(0.4) : tint.opacity(0.22), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.3), value: isComplete)
    }

    private var goalLabel: String {
        title == "Calories"
            ? Formatting.calories(goal)
            : Formatting.grams(goal)
    }
}
