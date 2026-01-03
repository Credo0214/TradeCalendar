import Foundation
import Combine

@MainActor
final class RiskCalculatorViewModel: ObservableObject {

    // MARK: - Input
    @Published var balanceText: String = ""
    @Published var riskPercentText: String = ""

    // MARK: - Output
    @Published private(set) var oneRText: String = ""
    @Published private(set) var twoRText: String = ""
    @Published private(set) var threeRText: String = ""

    // MARK: - Internal

    private var cancellables = Set<AnyCancellable>()

    init() {
        Publishers.CombineLatest($balanceText, $riskPercentText)
            .sink { [weak self] balanceText, riskText in
                self?.recalculate(balanceText: balanceText, riskText: riskText)
            }
            .store(in: &cancellables)
    }

    // MARK: - Calculation

    private func recalculate(balanceText: String, riskText: String) {
        guard
            let balance = Double(balanceText),
            let riskPercent = Double(riskText),
            balance > 0,
            riskPercent > 0
        else {
            oneRText = ""
            twoRText = ""
            threeRText = ""
            return
        }

        let rate = RiskRate(percent: riskPercent)

        let oneR = RiskCalculator.oneR(balance: balance, rate: rate)
        let twoR = RiskCalculator.nR(balance: balance, rate: rate, multiple: 2)
        let threeR = RiskCalculator.nR(balance: balance, rate: rate, multiple: 3)

        oneRText = NumberFormatters.yen(oneR.value)
        twoRText = NumberFormatters.yen(twoR.value)
        threeRText = NumberFormatters.yen(threeR.value)
    }
}

