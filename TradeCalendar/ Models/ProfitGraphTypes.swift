import Foundation

enum ProfitGraphRange: String, CaseIterable, Identifiable, Equatable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case all = "ALL"
    var id: String { rawValue }
}

struct CumulativeProfitPoint: Identifiable, Equatable {
    let id: Date
    let date: Date
    let cumulativeProfit: Double
}

struct MaxDrawdownInfo: Equatable {
    let peakDate: Date
    let troughDate: Date
    let peakValue: Double
    let troughValue: Double
    var drawdown: Double { troughValue - peakValue } // 負の値
}

struct GraphSelection: Equatable {
    let date: Date
    let dailyProfit: Double
    let cumulativeProfit: Double
}

