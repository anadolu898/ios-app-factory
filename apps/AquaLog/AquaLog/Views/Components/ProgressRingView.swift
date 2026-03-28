import SwiftUI

struct ProgressRingView: View {
    let progress: Double // 0.0 to 1.0+
    let lineWidth: CGFloat
    let size: CGFloat
    var gradientColors: [Color] = [Color.cyan, .accentColor]

    @State private var animatedProgress: Double = 0

    private var clampedProgress: Double {
        min(max(animatedProgress, 0), 1.0)
    }

    private var ringRadius: CGFloat {
        (size - lineWidth) / 2
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color(.systemGray5),
                    lineWidth: lineWidth
                )

            // Progress ring — solid color for clean appearance at all fill levels
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Hydration progress"))
        .accessibilityValue(String(localized: "\(Int((progress * 100).rounded())) percent"))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        ProgressRingView(progress: 0.65, lineWidth: 20, size: 200)
        ProgressRingView(progress: 1.0, lineWidth: 16, size: 150)
        ProgressRingView(progress: 0.3, lineWidth: 12, size: 100)
    }
    .padding()
}
