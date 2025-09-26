
import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var financialInstitutions: [FinancialInstitution] = []

    init() {
        loadFinancialInstitutions()
    }

    func loadFinancialInstitutions() {
        guard let url = Bundle.main.url(forResource: "financialInstitutions", withExtension: "json") else {
            print("financialInstitutions.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            financialInstitutions = try decoder.decode([FinancialInstitution].self, from: data)
        } catch {
            print("Error decoding financialInstitutions.json: \(error)")
        }
    }
}
