import SwiftUI
import Charts

struct ProfitGraphView: View {
    @ObservedObject var viewModel: ProfitGraphViewModel

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.dailyTotals.isEmpty {
                    Text("データがありません")
                        .foregroundStyle(.secondary)
                } else {
                    Chart {
                        ForEach(viewModel.dailyTotals, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Profit", item.profit)
                            )
                        }
                    }
                    .frame(height: 240)
                    .padding()
                }
                Spacer()
            }
            .navigationTitle("損益グラフ")
            .onAppear {
                viewModel.fetch()
            }
        }
    }
}

