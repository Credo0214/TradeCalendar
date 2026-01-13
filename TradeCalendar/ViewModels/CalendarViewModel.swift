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

    // 🔴 改善①：日次損益キャッシュ
    @Published private(set) var dailyTotals: [Date: Double] = [:]

    // MARK: - Init
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
            let fetched = try context.fetch(request)
            trades = fetched
            rebuildDailyTotals(from: fetched)   // ← キャッシュ構築
        } catch {
            trades = []
            dailyTotals = [:]
        }
    }

    // MARK: - Read API（Viewから呼ばれる）

    /// 指定日のトレード一覧（従来どおり）
    func trades(for date: Date) -> [TradeEntity] {
        trades.filter {
            guard let d = $0.date else { return false }
            return calendar.isDate(d, inSameDayAs: date)
        }
    }

    /// 指定日の損益合計（🔴 O(1)）
    func dailyTotal(on date: Date) -> Double {
        let day = calendar.startOfDay(for: date)
        return dailyTotals[day] ?? 0
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

    struct WinRateSummary {
        let wins: Int
        let total: Int

        var rate: Double {
            guard total > 0 else { return 0 }
            return Double(wins) / Double(total)
        }
    }

    /// 指定月の損益合計
    func monthlyTotal(for month: Date) -> Double {
        trades
            .filter {
                guard let d = $0.date else { return false }
                return calendar.isDate(d, equalTo: month, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.profit }
    }

    /// 指定月の勝率
    func monthlyWinRate(for month: Date) -> WinRateSummary? {
        let monthTrades = trades.filter {
            guard let d = $0.date else { return false }
            return calendar.isDate(d, equalTo: month, toGranularity: .month)
        }

        guard !monthTrades.isEmpty else { return nil }
        let wins = monthTrades.filter { $0.profit > 0 }.count
        return WinRateSummary(wins: wins, total: monthTrades.count)
    }

    /// 直近トレード後の総資金
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

    // MARK: - Cache Build（改善①の本体）

    private func rebuildDailyTotals(from trades: [TradeEntity]) {
        var dict: [Date: Double] = [:]

        for trade in trades {
            guard let date = trade.date else { continue }
            let day = calendar.startOfDay(for: date)
            dict[day, default: 0] += trade.profit
        }

        dailyTotals = dict
    }
}
