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

    static func yen(_ value: Double) -> String {
        yenCurrency.string(from: NSNumber(value: value)) ?? "¥0"
    }
}

