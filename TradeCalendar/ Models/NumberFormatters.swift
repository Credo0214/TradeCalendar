import Foundation

enum NumberFormatters {

    // ¥ + 桁区切り + 小数なし
    static let yenCurrency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "¥"
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    // パーセント表示（小数1桁）
    static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 1
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    static func yen(_ value: Double) -> String {
        yenCurrency.string(from: NSNumber(value: value)) ?? "¥0"
    }

    static func percentString(_ value: Double) -> String {
        percent.string(from: NSNumber(value: value)) ?? "0.0%"
    }
}

extension NumberFormatters {

    /// カレンダー用：短縮表示（例：¥12.5K / ¥1.2M）
    static func yenCompact(_ value: Double) -> String {
        let absValue = abs(value)

        let formatted: String
        switch absValue {
        case 1_000_000...:
            formatted = String(format: "%.1fM", absValue / 1_000_000)
        case 10_000...:
            formatted = String(format: "%.1fK", absValue / 1_000)
        default:
            formatted = String(Int(absValue))
        }

        return value < 0 ? "-¥\(formatted)" : "¥\(formatted)"
    }
}
