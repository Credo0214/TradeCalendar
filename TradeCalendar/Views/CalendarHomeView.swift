import SwiftUI
import CoreData

struct CalendarHomeView: View {
    
    @ObservedObject var viewModel: CalendarViewModel
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var settingsStore: AppSettingsStore
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    
    @State private var showAddTrade = false
    @State private var showDailySummary = false
    
    // ✅ 編集シート用（TradeEntityを直接持たず objectID を持つ）
    @State private var editSelection: TradeSelection? = nil
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // MARK: - Selection Wrapper
    private struct TradeSelection: Identifiable {
        let id: NSManagedObjectID
    }
    
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
                
                // カレンダー本体
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(dayCellsInMonth) { cell in
                        if let day = cell.date {
                            let profitForDay: Double = viewModel.dailyTotal(on: day)
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
                
                // 選択日の履歴（タップで編集）
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
                                    .lineLimit(1)
                                Spacer()
                                Text(NumberFormatters.yen(trade.profit))
                                    .foregroundStyle(trade.profit >= 0 ? Color("AppBlue") : .red)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // ✅ isPresented を使わず selection だけセット
                                editSelection = TradeSelection(id: trade.objectID)
                            }
                        }
                    }
                }
                
                Spacer()
                
                let monthlyTotal = viewModel.monthlyTotal(for: currentMonth)
                let winRateSummary = viewModel.monthlyWinRate(for: currentMonth)

                VStack(alignment: .leading, spacing: 4) {
                    Text("当月合計損益：\(NumberFormatters.yen(monthlyTotal))")
                        .font(.headline)
                        .foregroundStyle(monthlyTotal >= 0 ? Color("AppBlue") : .red)

                    if let summary = winRateSummary {
                        Text("勝率：\(NumberFormatters.percentString(summary.rate))（\(summary.wins)/\(summary.total)）")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("勝率：--（トレードなし）")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
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
            
            // 新規追加
            .sheet(isPresented: $showAddTrade) {
                TradeAddView(
                    initialBalanceBefore: viewModel.latestTotalBalance,
                    riskPercent: settingsStore.riskRate
                ) { pair, before, after, date, memo in
                    viewModel.addTrade(
                        pair: pair,
                        balanceBefore: before,
                        balanceAfter: after,
                        date: date,
                        memo: memo
                    )
                }
                .tint(Color("AppBlue"))
            }
            
            // ✅ 編集（item方式で「空シート」を根絶）
            .sheet(item: $editSelection) { sel in
                if let trade = (try? viewContext.existingObject(with: sel.id)) as? TradeEntity {
                    TradeEditView(
                        trade: trade,
                        riskPercent: settingsStore.riskRate,
                        onSave: { trade, pair, before, after, date, memo in
                            viewModel.updateTrade(
                                trade,
                                pair: pair,
                                balanceBefore: before,
                                balanceAfter: after,
                                date: date,
                                memo: memo
                            )
                            // 保存後に閉じたい場合はここで nil にする（任意）
                            // editSelection = nil
                        },
                        onDelete: { trade in
                            // ① 先にシートを閉じる（TradeEditView が trade を参照しなくなる）
                            editSelection = nil

                            // ② 次のUIターンで削除（表示中の参照を避ける）
                            Task { @MainActor in
                                viewModel.deleteTrade(trade)
                            }
                        },
                        onCancel: {
                            // ✅ 明示的に閉じる
                            editSelection = nil
                        }
                    )
                    .tint(Color("AppBlue"))
                } else {
                    VStack(spacing: 12) {
                        Text("編集データの読み込みに失敗しました")
                            .font(.headline)
                        Button("閉じる") {
                            editSelection = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("AppBlue"))
                    }
                    .padding()
                    .presentationDetents([.height(220)])
                }
            }
            
            
            // 日次合計の大表示
            .sheet(isPresented: $showDailySummary) {
                let total = viewModel.dailyTotal(on: selectedDate)
                
                VStack(spacing: 12) {
                    Text(selectedDate, format: .dateTime.year().month().day())
                        .font(.headline)
                    
                    Text(NumberFormatters.yen(total))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(total >= 0 ? Color("AppBlue") : .red)
                    
                    Text("日次合計")
                        .foregroundStyle(.secondary)
                    
                    Button("閉じる") {
                        showDailySummary = false
                    }
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
        
        // ✅ Array(repeating:) をやめて、空白セルも1個ずつ生成してID重複を防ぐ
        let blanks: [DayCell] = (0..<leadingBlanks).map { _ in DayCell(date: nil) }
        
        return blanks + days.map { DayCell(date: $0) }
    }
}
