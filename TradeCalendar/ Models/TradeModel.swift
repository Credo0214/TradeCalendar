import Foundation

struct TradeModel: Identifiable {
    let id: UUID
    let date: Date
    let pair: String
    let balanceBefore: Double
    let balanceAfter: Double
    let profit: Double
    let memo: String?
}

