import SwiftUI

struct CalendarMonthView: View {
    let currentMonth: Date
    let trades: [TradeModel]

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        let days = makeDays()

        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { day in
                VStack(spacing: 4) {
                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.caption)

                    let dailyProfit = trades
                        .filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
                        .map(\.profit)
                        .reduce(0, +)

                    if dailyProfit != 0 {
                        Text("\(dailyProfit, specifier: "%.0f")")
                            .font(.caption2)
                            .foregroundStyle(dailyProfit >= 0 ? .green : .red)
                    }
                }
                .frame(height: 44)
            }
        }
    }

    private func makeDays() -> [Date] {
        guard
            let interval = Calendar.current.dateInterval(of: .month, for: currentMonth)
        else { return [] }

        return Calendar.current.generateDates(
            inside: interval,
            matching: DateComponents(hour: 0)
        )
    }
}

