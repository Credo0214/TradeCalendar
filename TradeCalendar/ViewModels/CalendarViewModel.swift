import Foundation
import CoreData
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {

    // MARK: - Dependencies
    private let context: NSManagedObjectContext
    private let calendar = Calendar.current

    // MARK: - Published State
    @Published private(set) var trades: [TradeEntity] = []

    // MARK: - Init
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTrades()
    }

    // MARK: - Public Fetch API

    /// 全トレードを取得（date 昇順）
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

    // MARK: - Query / Read

    /// 指定日のトレード一覧
    func trades(for date: Date) -> [TradeEntity] {
        trades.filter {
            guard let d = $0.date else { return false }
            return calendar.isDate(d, inSameDayAs: date)
        }
    }

    /// 指定日の損益合計
    func dailyTotal(on date: Date) -> Double {
        trades(for: date).reduce(0) { $0 + $1.profit }
    }

    /// 当月損益合計
    var monthlyTotal: Double {
        let now = Date()
        return trades
            .filter {
                guard let d = $0.date else { return false }
                return calendar.isDate(d, equalTo: now, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.profit }
    }

    /// 直近トレード後の総資金（なければ 0）
    var latestTotalBalance: Double {
        trades
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
            .last?
            .balanceAfter ?? 0
    }

    // MARK: - Create

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

    // MARK: - Update

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

    // MARK: - Delete

    func deleteTrade(_ trade: TradeEntity) {
        context.delete(trade)
        saveAndRefresh()
    }

    // MARK: - Persistence

    private func saveAndRefresh() {
        do {
            try context.save()
            fetchTrades()
        } catch {
            context.rollback()
        }
    }
}
