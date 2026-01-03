import Foundation
import Combine

final class TradeListViewModel: ObservableObject {
    @Published var trades: [TradeModel] = []

    func trades(for date: Date) -> [TradeModel] {
        let calendar = Calendar.current
        return trades.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }
}

