import Foundation
import Combine

final class StatisticsViewModel: ObservableObject {
    func dailyTotal(trades: [TradeModel], date: Date) -> Double {
        let calendar = Calendar.current
        return trades
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .map(\.profit)
            .reduce(0, +)
    }
}

