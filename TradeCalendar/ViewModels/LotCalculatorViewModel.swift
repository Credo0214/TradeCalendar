import Foundation
import Combine

final class LotCalculatorViewModel: ObservableObject {

    @Published var capital: Double = 0
    @Published var riskRate: Double = 0.05
    @Published var stopLossPips: Double = 0

    var allowableLoss: Double {
        capital * riskRate
    }

    var lotSize: Double {
        guard stopLossPips > 0 else { return 0 }
        return allowableLoss / stopLossPips
    }
}

