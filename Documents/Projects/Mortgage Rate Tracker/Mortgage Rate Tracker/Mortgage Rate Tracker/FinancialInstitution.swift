
import Foundation

struct FinancialInstitution: Codable, Identifiable {
    let id = UUID()
    let name: String
    let website: [String]
}
