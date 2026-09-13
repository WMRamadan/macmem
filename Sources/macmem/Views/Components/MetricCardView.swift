import SwiftUI

/// A reusable, elegant card displaying a single metric with icon, title, value, and subtitle.
public struct MetricCardView: View {
    public let title: String
    public let value: String
    public var subtitle: String? = nil
    public var icon: String? = nil
    public var iconColor: Color = .blue
    public var accentColor: Color = .primary
    public var badge: String? = nil
    public var badgeColor: Color = .secondary

    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = .blue,
        accentColor: Color = .primary,
        badge: String? = nil,
        badgeColor: Color = .secondary
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.accentColor = accentColor
        self.badge = badge
        self.badgeColor = badgeColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeColor.opacity(0.15))
                        .foregroundColor(badgeColor)
                        .cornerRadius(6)
                }
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
