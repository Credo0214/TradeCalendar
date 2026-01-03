import SwiftUI
import Charts
import CoreData

struct ProfitGraphView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var vm: ProfitGraphViewModel

    init(context: NSManagedObjectContext) {
        _vm = StateObject(wrappedValue: ProfitGraphViewModel(context: context))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("損益グラフ")
                .font(.headline)

            Picker("期間", selection: $vm.selectedRange) {
                ForEach(ProfitGraphRange.allCases) { r in
                    Text(r.rawValue).tag(r)
                }
            }
            .pickerStyle(.segmented)
            .tint(Color("AppBlue"))

            if vm.dailyPoints.isEmpty && vm.cumulativePoints.isEmpty {
                ContentUnavailableView(
                    "データがありません",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("トレードを追加するとグラフが表示されます。")
                )
            } else {
                cumulativeChart
                dailyBarChart
            }

            Spacer(minLength: 0)
        }
        .padding()
        .onAppear {
            vm.replaceContextIfNeeded(context)
            vm.reload()
        }
        .tint(Color("AppBlue"))
    }

    private var dayXAxis: some AxisContent {
        AxisMarks(values: .stride(by: .day)) { _ in
            AxisGridLine()
            AxisTick()
            AxisValueLabel(format: .dateTime.month().day())
        }
    }

    private var cumulativeChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("累積損益")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart {
                RuleMark(y: .value("BreakEven", 0))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)

                if let dd = vm.maxDrawdown {
                    RuleMark(y: .value("DD Peak", dd.peakValue))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 6]))
                        .foregroundStyle(.secondary)

                    RuleMark(y: .value("DD Trough", dd.troughValue))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 6]))
                        .foregroundStyle(.secondary)
                        .annotation(position: .topLeading) {
                            Text("Max DD: \(formatYen(dd.drawdown))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                }

                // 累積：青固定
                ForEach(vm.cumulativePoints) { p in
                    LineMark(
                        x: .value("Date", p.date),
                        y: .value("Cumulative", p.cumulativeProfit)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color("AppBlue"))

                    PointMark(
                        x: .value("Date", p.date),
                        y: .value("Cumulative", p.cumulativeProfit)
                    )
                    .foregroundStyle(Color("AppBlue"))
                }

                if let sel = vm.selection {
                    RuleMark(x: .value("Selected", sel.date))
                        .foregroundStyle(.secondary)

                    PointMark(
                        x: .value("Selected Date", sel.date),
                        y: .value("Selected Cum", sel.cumulativeProfit)
                    )
                    .annotation(position: .topTrailing) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(dateLabel(sel.date))
                            Text("累積 \(formatYen(sel.cumulativeProfit))")
                            Text("日次 \(formatYen(sel.dailyProfit))")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .chartXAxis { dayXAxis }
            .chartYScale(domain: .automatic(includesZero: true))
            .applyXDomain(vm.xDomain)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard let plotFrame = proxy.plotFrame else {
                                        return
                                    }

                                    let origin = geo[plotFrame].origin
                                    let locationX = value.location.x - origin.x

                                    let date: Date? = proxy.value(atX: locationX)
                                    vm.selectNearest(to: date)
                                }
                        )
                }
            }
            .frame(height: 240)
        }
    }

    private var dailyBarChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("日次損益")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(vm.dailyPoints) { p in
                    BarMark(
                        x: .value("Date", p.date),
                        y: .value("Daily", p.profit)
                    )
                    .foregroundStyle(p.profit >= 0 ? Color("AppBlue") : Color.red)
                }

                if let sel = vm.selection {
                    RuleMark(x: .value("Selected", sel.date))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis { dayXAxis }
            .applyXDomain(vm.xDomain)
            .frame(height: 180)
        }
    }

    private func formatYen(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencySymbol = "¥"
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: value)) ?? "¥0"
    }

    private func dateLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "M/d"
        return df.string(from: date)
    }
}

private extension View {
    @ViewBuilder
    func applyXDomain(_ domain: ClosedRange<Date>?) -> some View {
        if let domain {
            self.chartXScale(domain: domain)
        } else {
            self
        }
    }
}
