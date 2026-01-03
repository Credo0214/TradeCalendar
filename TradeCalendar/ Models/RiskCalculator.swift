import Foundation

/// リスク率（%）
/// 例: 5 = 5%
/// 製品安全側: 0 < value <= 100 を想定（バリデーションは Settings 側で実施）
struct RiskRate: Equatable {
    let percent: Double

    init(percent: Double) {
        self.percent = percent
    }

    var fraction: Double {
        percent / 100.0
    }
}

/// 許容損失額（1R）
struct RiskAmount: Equatable {
    let value: Double
}

/// 目標値（2R/3Rなど）
struct TargetAmount: Equatable {
    let value: Double
}

/// リスク計算はここだけが責務を持つ（SSOT for Risk Calculation）
enum RiskCalculator {

    /// 1R（許容損失額）
    static func oneR(balance: Double, rate: RiskRate) -> RiskAmount {
        RiskAmount(value: max(0, balance) * rate.fraction)
    }

    /// nR（2R/3Rなど）
    static func nR(balance: Double, rate: RiskRate, multiple: Double) -> TargetAmount {
        let one = oneR(balance: balance, rate: rate).value
        return TargetAmount(value: one * max(0, multiple))
    }

    /// 損益（資金差分）
    static func profit(balanceBefore: Double, balanceAfter: Double) -> Double {
        balanceAfter - balanceBefore
    }
}
