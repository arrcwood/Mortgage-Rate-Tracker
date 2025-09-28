import Foundation
import Combine

struct LoanParameters: Codable {
    var purchasePrice: Int
    var downPayment: Int
    var zipCode: String

    static let defaultParameters = LoanParameters(
        purchasePrice: 250000,
        downPayment: 50000,
        zipCode: "95464"
    )

    var loanAmount: Int {
        return purchasePrice - downPayment
    }

    var downPaymentPercentage: Double {
        guard purchasePrice > 0 else { return 0 }
        return Double(downPayment) / Double(purchasePrice) * 100
    }

    func isValid() -> Bool {
        return purchasePrice > 0 &&
               downPayment >= 0 &&
               zipCode.count == 5 &&
               zipCode.allSatisfy { $0.isNumber }
    }
}

class LoanParametersViewModel: ObservableObject {
    @Published var parameters = LoanParameters.defaultParameters
    @Published var showingParametersSheet = false

    func updateParameters(_ newParameters: LoanParameters) {
        parameters = newParameters
    }
}