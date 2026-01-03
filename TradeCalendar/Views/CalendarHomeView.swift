import SwiftUI
import CoreData

struct CalendarHomeView: View {

    @ObservedObject var viewModel: CalendarViewModel
    @EnvironmentObject private var settingsStore: AppSettingsStore

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

                HStack {
                    Button {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    } label: { Image(systemName: "chevron.left") }

                    Spacer()

                    Text(currentMonth.formatted(.dateTime.year().month()))
                        .font(.title2.bold())

                    Spacer()

                    Button {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    } label: { Image(systemName: "chevron.right") }
                }

                HStack {
                    ForEach(weekdaySymbols, id: \.self) { s in
                        Text(s)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.secondary)
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(dayCellsInMonth) { cell in
                        if let day = cell.date {
                            let profitForDay = viewModel.dailyTotal(on: day)
                            let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)

                            Button {
                                selectedDate = day
                                showDailySummary = true
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(calendar.component(.day, from: day))")
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    if profitForDay != 0 {
                                        Text(NumberFormatters.yenCompact(profitForDay))
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(profitForDay >= 0 ? Color("AppBlue") : .red)
                                            .clipShape(Capsule())
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(isSelected ? Color("AppBlue").opacity(0.22) : Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("AppBlue"), lineWidth: 2)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 56)
                        }
                    }
                }

                Divider()

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
                                    .foregroundStyle(trade.profit >= 0 ? Color("AppBlue") : .red)
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

                Text("当月合計損益：\(NumberFormatters.yen(viewModel.monthlyTotal))")
                    .font(.headline)
                    .foregroundStyle(viewModel.monthlyTotal >= 0 ? Color("AppBlue") : .red)

                Button {
                    showAddTrade = true
                } label: {
                    Label("新規トレード", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AppBlue"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()

            .sheet(isPresented: $showAddTrade) {
                TradeAddView(
                    initialBalanceBefore: viewModel.latestTotalBalance,
                    riskPercent: settingsStore.riskRate   // ✅ SSOT から取得
                ) { pair, before, after, date, memo in
                    viewModel.addTrade(pair: pair, balanceBefore: before, balanceAfter: after, date: date, memo: memo)
                }
                .tint(Color("AppBlue"))
            }

            .sheet(isPresented: $showEditTrade) {
                let vm = viewModel
                if let trade = editingTrade {
                    TradeEditView(
                        trade: trade,
                        riskPercent: settingsStore.riskRate, // ✅ SSOT
                        onSave: { trade, pair, before, after, date, memo in
                            vm.updateTrade(trade, pair: pair, balanceBefore: before, balanceAfter: after, date: date, memo: memo)
                        },
                        onDelete: { trade in
                            vm.deleteTrade(trade)
                        }
                    )
                    .tint(Color("AppBlue"))
                }
            }

            .sheet(isPresented: $showDailySummary) {
                let total = viewModel.dailyTotal(on: selectedDate)

                VStack(spacing: 12) {
                    Text(selectedDate, format: .dateTime.year().month().day())
                        .font(.headline)

                    Text(NumberFormatters.yen(total))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(total >= 0 ? Color("AppBlue") : .red)

                    Text("日次合計").foregroundStyle(.secondary)

                    Button("閉じる") { showDailySummary = false }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("AppBlue"))
                        .padding(.top, 8)
                }
                .padding()
                .presentationDetents([.height(240)])
                .tint(Color("AppBlue"))
            }
        }
        .tint(Color("AppBlue"))
    }

    // MARK: - Helpers

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
