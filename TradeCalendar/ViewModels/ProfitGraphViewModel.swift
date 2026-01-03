import Foundation
import CoreData
import Combine

@MainActor
final class ProfitGraphViewModel: ObservableObject {

    // MARK: - Published (Output)

    @Published private(set) var dailyPoints: [DailyProfitPoint] = []
    @Published private(set) var cumulativePoints: [CumulativeProfitPoint] = []

    /// X軸ドメイン（最新日を右端に寄せるため、右に1日パディング）
    @Published private(set) var xDomain: ClosedRange<Date>?

    /// 最大DD
    @Published private(set) var maxDrawdown: MaxDrawdownInfo?

    /// タップ選択
    @Published private(set) var selection: GraphSelection?

    // MARK: - Published (Input)

    @Published var selectedRange: ProfitGraphRange = .oneMonth {
        didSet {
            // 外部からの変更経路を安全側で吸収
            Task { @MainActor in
                self.reload()
            }
        }
    }

    // MARK: - Dependencies / Internal

    private var context: NSManagedObjectContext
    private let calendar: Calendar
    private var contextObserver: NSObjectProtocol?

    // MARK: - Init / Deinit

    init(context: NSManagedObjectContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
        bindContextChanges()
        reload()
    }

    deinit {
        if let contextObserver {
            NotificationCenter.default.removeObserver(contextObserver)
        }
    }

    // MARK: - Public API

    func replaceContextIfNeeded(_ newContext: NSManagedObjectContext) {
        if context === newContext { return }
        context = newContext
        bindContextChanges()
        reload()
    }

    /// データ再構築（期間フィルタを含む）
    func reload(now: Date = Date()) {
        let request = NSFetchRequest<TradeEntity>(entityName: "TradeEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        if let range = makeDateInterval(now: now) {
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@",
                range.start as NSDate,
                range.end as NSDate
            )
        }

        do {
            let trades = try context.fetch(request)
            rebuildPoints(from: trades)
        } catch {
            // 最小安全動作：落とさずクリア
            dailyPoints = []
            cumulativePoints = []
            xDomain = nil
            maxDrawdown = nil
            selection = nil
        }
    }

    /// タップされた日付に最も近い日次点を選択（累積/日次を同期）
    func selectNearest(to date: Date?) {
        guard let date else { return }
        guard !dailyPoints.isEmpty else { return }

        let targetDay = calendar.startOfDay(for: date)

        let nearest = dailyPoints.min { a, b in
            abs(a.date.timeIntervalSince(targetDay)) < abs(b.date.timeIntervalSince(targetDay))
        }
        guard let nearest else { return }

        let cum = cumulativePoints.first(where: { $0.date == nearest.date })?.cumulativeProfit
            ?? cumulativePoints.min { a, b in
                abs(a.date.timeIntervalSince(nearest.date)) < abs(b.date.timeIntervalSince(nearest.date))
            }?.cumulativeProfit
            ?? 0

        selection = GraphSelection(date: nearest.date, dailyProfit: nearest.profit, cumulativeProfit: cum)
    }

    func clearSelection() {
        selection = nil
    }

    // MARK: - Context Observe

    private func bindContextChanges() {
        if let contextObserver {
            NotificationCenter.default.removeObserver(contextObserver)
        }

        contextObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: context,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.reload()
            }
        }
    }

    // MARK: - Build Points

    private func rebuildPoints(from trades: [TradeEntity]) {
        // date nil は除外
        let valid: [(day: Date, profit: Double)] = trades.compactMap { t in
            guard let d = t.date else { return nil }
            return (calendar.startOfDay(for: d), t.profit)
        }

        // 日次合算
        let grouped = Dictionary(grouping: valid, by: { $0.day })
        let daily: [DailyProfitPoint] = grouped
            .map { (day, items) in
                let sum = items.reduce(0.0) { $0 + $1.profit }
                return DailyProfitPoint(id: day, date: day, profit: sum)
            }
            .sorted { $0.date < $1.date }

        dailyPoints = daily

        // 累積（期間開始=0）
        var running = 0.0
        let cumulative: [CumulativeProfitPoint] = daily.map { p in
            running += p.profit
            return CumulativeProfitPoint(id: p.date, date: p.date, cumulativeProfit: running)
        }
        cumulativePoints = cumulative

        // X軸ドメイン（右に1日パディングして最新を右端へ）
        if let first = daily.first?.date, let last = daily.last?.date {
            let end = calendar.date(byAdding: .day, value: 1, to: last) ?? last
            xDomain = first...end
        } else {
            xDomain = nil
        }

        // 最大DD
        maxDrawdown = computeMaxDrawdown(from: cumulative)

        // 既存 selection が期間外になったらクリア
        if let sel = selection, daily.first(where: { $0.date == sel.date }) == nil {
            selection = nil
        }
    }

    // MARK: - Max Drawdown

    private func computeMaxDrawdown(from points: [CumulativeProfitPoint]) -> MaxDrawdownInfo? {
        guard points.count >= 2 else { return nil }

        var peakValue = points[0].cumulativeProfit
        var peakDate = points[0].date

        var best: MaxDrawdownInfo?

        for p in points {
            // 新高値なら peak 更新
            if p.cumulativeProfit > peakValue {
                peakValue = p.cumulativeProfit
                peakDate = p.date
                continue
            }

            let dd = p.cumulativeProfit - peakValue // 負
            if let currentBest = best {
                if dd < currentBest.drawdown {
                    best = MaxDrawdownInfo(
                        peakDate: peakDate,
                        troughDate: p.date,
                        peakValue: peakValue,
                        troughValue: p.cumulativeProfit
                    )
                }
            } else if dd < 0 {
                best = MaxDrawdownInfo(
                    peakDate: peakDate,
                    troughDate: p.date,
                    peakValue: peakValue,
                    troughValue: p.cumulativeProfit
                )
            }
        }

        return best
    }

    // MARK: - Date Interval

    private func makeDateInterval(now: Date) -> DateInterval? {
        let end = now
        let startThisMonth = calendar.startOfMonth(for: now)

        switch selectedRange {
        case .oneMonth:
            return DateInterval(start: startThisMonth, end: end)

        case .threeMonths:
            let start = calendar.date(byAdding: .month, value: -2, to: startThisMonth) ?? startThisMonth
            return DateInterval(start: start, end: end)

        case .all:
            let minReq = NSFetchRequest<TradeEntity>(entityName: "TradeEntity")
            minReq.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            minReq.fetchLimit = 1

            do {
                let first = try context.fetch(minReq).first
                guard let firstDate = first?.date else { return nil }
                let start = calendar.startOfMonth(for: firstDate)
                return DateInterval(start: start, end: end)
            } catch {
                return nil
            }
        }
    }
}

