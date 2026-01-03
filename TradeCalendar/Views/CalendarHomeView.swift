import SwiftUI

struct CalendarHomeView: View {

    @ObservedObject var viewModel: CalendarViewModel

    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()

    @State private var showAddTrade = false

    @State private var editingTrade: TradeEntity?
    @State private var showEditTrade = false
    
    @State private var showDailySummary = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                Text("トレードカレンダー")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 月切替
                HStack {
                    Button {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(monthTitle)
                        .font(.title2.bold())

                    Spacer()

                    Button {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }

                // 曜日（firstWeekday に合わせる）
                HStack {
                    ForEach(weekdaySymbols, id: \.self) { s in
                        Text(s)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.secondary)
                    }
                }

                // カレンダー本体（空白セル込み）
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(dayCellsInMonth) { cell in
                        if let day = cell.date {

                            let profitForDay: Double = { viewModel.dailyTotal(on: day) }()

                            Button {
                                selectedDate = day
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(calendar.component(.day, from: day))")
                                        .font(.headline)

                                    if profitForDay != 0 {
                                        // 見た目を優先するならバッジは数値のみでもOKだが、統一のため¥表示
                                        Text(NumberFormatters.yenCompact(profitForDay))
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                            .lineLimit(1)                 // ★ 改行禁止
                                            .minimumScaleFactor(0.7)      // ★ どうしても長い時は縮小
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                (profitForDay > 0 ? Color.green : Color.red)
                                                    .frame(maxWidth: 60)   // ← これ以上広がらない
                                            )

                                            .clipShape(Capsule())
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(
                                    calendar.isDate(day, inSameDayAs: selectedDate)
                                    ? Color.blue.opacity(0.25)
                                    : Color(.systemGray5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)

                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 56)
                        }
                    }
                }

                Divider()

                // 選択日の履歴
                VStack(alignment: .leading, spacing: 8) {
                    Text("選択日：\(selectedDate, format: .dateTime.year().month().day())")
                        .font(.headline)

                    let dailyTrades = viewModel.trades(for: selectedDate)

                    if dailyTrades.isEmpty {
                        Text("トレード履歴はありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(dailyTrades) { trade in
                            HStack {
                                Text(trade.memo ?? (trade.pair ?? ""))
                                Spacer()
                                Text(NumberFormatters.yen(trade.profit))
                                    .foregroundStyle(trade.profit >= 0 ? .green : .red)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingTrade = trade
                                showEditTrade = true
                            }
                        }
                    }
                }

                Spacer()

                // 月合計（¥ + 桁区切り）
                Text("当月合計損益：\(NumberFormatters.yen(viewModel.monthlyTotal))")
                    .font(.headline)
                    .foregroundStyle(viewModel.monthlyTotal >= 0 ? .green : .red)

                Button {
                    showAddTrade = true
                } label: {
                    Label("新規トレード", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()

            // 新規追加
            .sheet(isPresented: $showAddTrade) {
                TradeAddView { pair, before, after, date, memo in
                    viewModel.addTrade(
                        pair: pair,
                        balanceBefore: before,
                        balanceAfter: after,
                        date: date,
                        memo: memo
                    )
                }
            }

            // 編集 + 削除（dynamicMember 回避）
            .sheet(isPresented: $showEditTrade) {
                let vm = viewModel
                if let trade = editingTrade {
                    TradeEditView(
                        trade: trade,
                        onSave: { trade, pair, before, after, date, memo in
                            vm.updateTrade(
                                trade,
                                pair: pair,
                                balanceBefore: before,
                                balanceAfter: after,
                                date: date,
                                memo: memo
                            )
                        },
                        onDelete: { trade in
                            vm.deleteTrade(trade)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private var monthTitle: String {
        currentMonth.formatted(.dateTime.year().month())
    }

    private struct DayCell: Identifiable {
        let id = UUID()
        let date: Date?
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private var dayCellsInMonth: [DayCell] {
        guard
            let interval = calendar.dateInterval(of: .month, for: currentMonth),
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }

        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        let days = calendar.generateDates(
            inside: interval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )

        return Array(repeating: DayCell(date: nil), count: leadingBlanks)
            + days.map { DayCell(date: $0) }
    }
}

