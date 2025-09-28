
import Foundation

struct FinancialInstitution: Codable, Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let mortgageTypes: [String]
    let fields: [Field]
    var selectedMortgageTypes: Set<String> = []

    struct Field: Codable {
        let name: String
        let label: String
    }

    enum CodingKeys: String, CodingKey {
        case name, url, mortgageTypes, fields
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        mortgageTypes = try container.decode([String].self, forKey: .mortgageTypes)
        fields = try container.decode([Field].self, forKey: .fields)
        selectedMortgageTypes = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(mortgageTypes, forKey: .mortgageTypes)
        try container.encode(fields, forKey: .fields)
    }
}

struct BankRatesData: Codable {
    let banks: [FinancialInstitution]
}
