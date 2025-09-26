
import Foundation

struct MortgageRate: Identifiable {
    let id = UUID()
    let loanType: String
    let interestRate: String
    let discountPoints: String
    let apr: String
}
