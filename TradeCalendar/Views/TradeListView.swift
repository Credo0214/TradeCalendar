import SwiftUI

struct TradeListView: View {
    let trades: [TradeModel]

    var body: some View {
        List(trades) { trade in
            Text(NumberFormatters.yen(trade.profit))
                .foregroundStyle(trade.profit >= 0 ? .green : .red)
        }
    }
}
