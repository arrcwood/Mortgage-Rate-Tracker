import Foundation
import SwiftData

@Model
final class RateRecord {
    var date: Date
    var loanType: String
    var interestRate: String
    var apr: String

    init(date: Date, loanType: String, interestRate: String, apr: String) {
        self.date = date
        self.loanType = loanType
        self.interestRate = interestRate
        self.apr = apr
    }
}