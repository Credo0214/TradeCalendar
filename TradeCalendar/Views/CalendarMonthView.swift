import SwiftUI

struct CalendarMonthView: View {
    let currentMonth: Date
    let trades: [TradeModel]

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private struct Day: Identifiable {
        let id = UUID()
        let date: Date
    }

    var body: some View {
        let days = makeDays()

        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days) { day in
                VStack(spacing: 4) {
                    Text("\(Calendar.current.component(.day, from: day.date))")
                        .font(.caption)

                    let dailyProfit = trades
                        .filter { Calendar.current.isDate($0.date, inSameDayAs: day.date) }
                        .map(\.profit)
                        .reduce(0, +)

                    if dailyProfit != 0 {
                        Text("\(dailyProfit, specifier: "%.0f")")
                            .font(.caption2)
                            .foregroundStyle(dailyProfit >= 0 ? Color("AppBlue") : .red)
                    }
                }
                .frame(height: 44)
            }
        }
    }

    private func makeDays() -> [Day] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: currentMonth) else { return [] }
        return Calendar.current.generateDates(inside: interval, matching: DateComponents(hour: 0))
            .map { Day(date: $0) }
    }
}
