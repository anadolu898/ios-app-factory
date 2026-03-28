import SwiftUI

struct ProgressRingView: View {
    let progress: Double // 0.0 to 1.0+
    let lineWidth: CGFloat
    let size: CGFloat
    var gradientColors: [Color] = [.accentColor, Color.blue.opacity(0.6)]

    @State private var animatedProgress: Double = 0

    private var clampedProgress: Double {
        min(max(animatedProgress, 0), 1.0)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color(.systemGray5),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            // End cap circle for polish
            if clampedProgress > 0.02 {
                Circle()
                    .fill(gradientColors.last ?? Color.blue.opacity(0.6))
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(360 * clampedProgress - 90))
            }
        }
        .frame(width: size, height: size)
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
