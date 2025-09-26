
import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var financialInstitutions: [FinancialInstitution] = []

    private let json_data = """
    [
        {
            "name": "Bank of America",
            "website": [
                "https://www.bankofamerica.com/mortgage/home-mortgage/"
            ]
        },
        {
            "name": "Charles Schwab",
            "website": [
                "https://www.schwab.com/mortgages/mortgage-rates"
            ]
        },
        {
            "name": "Chase",
            "website": [
                "https://www.chase.com/personal/mortgage/mortgage-rates"
            ]
        },
        {
            "name": "Citi",
            "website": [
                "https://www.citi.com/mortgage/purchase-rates"
            ]
        },
        {
            "name": "HSBC USA",
            "website": [
                "https://www.us.hsbc.com/home-loans/products/mortgage-rates/"
            ]
        },
        {
            "name": "Institution for Savings",
            "website": [
                "https://www.institutionforsavings.com/rates/residential-loans"
            ]
        },
        {
            "name": "Navy Federal Credit Union",
            "website": [
                "https://www.navyfederal.org/loans-cards/mortgage/mortgage-rates.html"
            ]
        },
        {
            "name": "Regions Bank",
            "website": [
                "https://www.regions.com/personal-banking/home-loans"
            ]
        },
        {
            "name": "U.S. Bank",
            "website": [
                "https://www.usbank.com/home-loans/mortgage/mortgage-rates.html"
            ]
        },
        {
            "name": "Wells Fargo",
            "website": [
                "https://www.wellsfargo.com/mortgage/rates/"
            ]
        }
    ]
    """

    init() {
        loadFinancialInstitutions()
    }

    func loadFinancialInstitutions() {
        let data = Data(json_data.utf8)
        do {
            let decoder = JSONDecoder()
            financialInstitutions = try decoder.decode([FinancialInstitution].self, from: data)
        } catch {
            print("Error decoding financialInstitutions.json: \(error)")
        }
    }
}
