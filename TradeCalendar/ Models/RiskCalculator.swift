import Foundation

enum RiskCalculator {
    /// riskPercent: 例 5 → 0.05 に正規化して計算
    static func allowedLoss(balance: Double, riskPercent: Double) -> Double? {
        guard balance > 0, riskPercent > 0 else { return nil }
        let risk = riskPercent / 100.0
        return balance * risk
    }
}

