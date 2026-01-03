import SwiftUI

struct TradeListView: View {
    let trades: [TradeModel]

    var body: some View {
        List(trades) {
            Text("\($0.profit, specifier: "%.2f")")
        }
    }
}

