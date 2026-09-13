import Foundation

/// Utility for converting byte counts into human-readable formatted strings.
public struct ByteFormatter: Sendable {

    /// Formats a byte count into a readable string (e.g., "14.2 GB", "512 MB", "0 B").
    /// - Parameters:
    ///   - bytes: The quantity in bytes.
    ///   - fractionDigits: Number of decimal places to include (default: 1).
    ///   - binary: Binary (1024-based, KiB/MiB/GiB labeled as KB/MB/GB) or Decimal (1000-based).
    ///   - locale: Locale for number formatting (defaults to POSIX with dot decimal separator).
    public static func format(
        _ bytes: UInt64,
        fractionDigits: Int = 1,
        binary: Bool = true,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> String {
        let divisor: Double = binary ? 1024.0 : 1000.0
        let doubleBytes = Double(bytes)

        if doubleBytes < divisor {
            return "\(bytes) B"
        }

        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = doubleBytes
        var unitIndex = 0

        while value >= divisor && unitIndex < units.count - 1 {
            value /= divisor
            unitIndex += 1
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.numberStyle = .decimal

        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(fractionDigits)f", value)
        return "\(formattedNumber) \(units[unitIndex])"
    }

    /// Returns a formatted percentage string (e.g., "45.2%").
    public static func formatPercentage(
        _ fraction: Double,
        fractionDigits: Int = 1,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> String {
        let clamped = max(0.0, min(1.0, fraction)) * 100.0
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: clamped)) ?? String(format: "%.\(fractionDigits)f", clamped)
        return "\(formatted)%"
    }

    /// Converts bytes to gigabytes as a Double for charting.
    public static func toGigabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / (1024.0 * 1024.0 * 1024.0)
    }

    /// Converts bytes to megabytes as a Double for charting.
    public static func toMegabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / (1024.0 * 1024.0)
    }
}
