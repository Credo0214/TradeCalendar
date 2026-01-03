import Foundation
import CoreData
import Combine

final class ProfitGraphViewModel: ObservableObject {

    @Published var dailyTotals: [(date: Date, profit: Double)] = []

    private let context: NSManagedObjectContext
    private let calendar = Calendar.current

    init(context: NSManagedObjectContext) {
        self.context = context
        fetch()
    }

    // MARK: - Fetch & Aggregate

    func fetch() {
        let request = TradeEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TradeEntity.date, ascending: true)
        ]

        let trades = (try? context.fetch(request)) ?? []

        // date が nil のものを安全に除外
        let validTrades: [(date: Date, profit: Double)] = trades.compactMap { trade in
            guard let date = trade.date else { return nil }
            return (date: calendar.startOfDay(for: date), profit: trade.profit)
        }

        let grouped = Dictionary(grouping: validTrades) { $0.date }

        dailyTotals = grouped
            .map { (date, items) in
                let total = items.reduce(0) { $0 + $1.profit }
                return (date: date, profit: total)
            }
            .sorted { $0.date < $1.date }
    }
}

