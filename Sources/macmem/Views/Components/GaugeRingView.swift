import SwiftUI

/// A circular gauge ring displaying a progress percentage with custom colors and center text.
public struct GaugeRingView: View {
    public let progress: Double
    public let title: String
    public let valueText: String
    public var subtitle: String? = nil
    public var gradient: Gradient = Gradient(colors: [.blue, .cyan])
    public var lineWidth: CGFloat = 12
    public var size: CGFloat = 130

    public init(
        progress: Double,
        title: String,
        valueText: String,
        subtitle: String? = nil,
        gradient: Gradient = Gradient(colors: [.blue, .cyan]),
        lineWidth: CGFloat = 12,
        size: CGFloat = 130
    ) {
        self.progress = max(0.0, min(1.0, progress))
        self.title = title
        self.valueText = valueText
        self.subtitle = subtitle
        self.gradient = gradient
        self.lineWidth = lineWidth
        self.size = size
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(
                        Color.primary.opacity(0.08),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )

                // Foreground Progress Arc
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(
                        AngularGradient(
                            gradient: gradient,
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)

                // Center Content
                VStack(spacing: 2) {
                    Text(valueText)
                        .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(title)
                        .font(.system(size: size * 0.09, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
            .frame(width: size, height: size)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
