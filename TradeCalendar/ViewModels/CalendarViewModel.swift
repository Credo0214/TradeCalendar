import Foundation
import CoreData
import Combine

final class CalendarViewModel: ObservableObject {

    private let context: NSManagedObjectContext
    private let calendar = Calendar.current

    @Published private(set) var trades: [TradeEntity] = []

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTrades()
    }

    // MARK: - Fetch

    func fetchTrades() {
        let request: NSFetchRequest<TradeEntity> = TradeEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TradeEntity.date, ascending: true)
        ]
        do {
            trades = try context.fetch(request)
        } catch {
            trades = []
        }
    }

    // MARK: - Query

    func trades(for date: Date) -> [TradeEntity] {
        trades.filter { trade in
            guard let d = trade.date else { return false }
            return calendar.isDate(d, inSameDayAs: date)
        }
    }

    func dailyTotal(on date: Date) -> Double {
        trades(for: date).reduce(0) { $0 + $1.profit }
    }

    var monthlyTotal: Double {
        let now = Date()
        return trades.filter { trade in
            guard let d = trade.date else { return false }
            return calendar.isDate(d, equalTo: now, toGranularity: .month)
        }
        .reduce(0) { $0 + $1.profit }
    }

    // MARK: - Add (新規)

    func addTrade(
        pair: String,
        balanceBefore: Double,
        balanceAfter: Double,
        date: Date,
        memo: String?
    ) {
        let trade = TradeEntity(context: context)
        trade.id = UUID()
        trade.date = date
        trade.memo = memo

        trade.pair = pair
        trade.balanceBefore = balanceBefore
        trade.balanceAfter = balanceAfter
        trade.profit = balanceAfter - balanceBefore

        saveAndRefresh()
    }

    // MARK: - Update (編集)

    func updateTrade(
        _ trade: TradeEntity,
        pair: String,
        balanceBefore: Double,
        balanceAfter: Double,
        date: Date,
        memo: String?
    ) {
        trade.pair = pair
        trade.balanceBefore = balanceBefore
        trade.balanceAfter = balanceAfter
        trade.date = date
        trade.memo = memo
        trade.profit = balanceAfter - balanceBefore

        saveAndRefresh()
    }

    // MARK: - Save

    private func saveAndRefresh() {
        do {
            try context.save()
            fetchTrades()
        } catch {
            context.rollback()
        }
    }
    // MARK: - Delete
    func deleteTrade(_ trade: TradeEntity) {
        context.delete(trade)

        do {
            try context.save()
            fetchTrades()
        } catch {
            context.rollback()
        }
    }

}
