
import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var financialInstitutions: [FinancialInstitution] = []
    @Published var expandedBanks: Set<UUID> = []
    @Published var loanParameters = LoanParameters.defaultParameters
    @Published var showingParametersSheet = false

    init() {
        loadFinancialInstitutions()
        loadSelectedMortgageTypes()
        loadLoanParameters()
    }

    func loadFinancialInstitutions() {
        guard let url = Bundle.main.url(forResource: "bankRates", withExtension: "json") else {
            print("Could not find bankRates.json file")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let bankRatesData = try decoder.decode(BankRatesData.self, from: data)
            financialInstitutions = bankRatesData.banks
        } catch {
            print("Error decoding bankRates.json: \(error)")
        }
    }

    func refreshData() {
        loadFinancialInstitutions()
        loadSelectedMortgageTypes()
    }

    func clearCachedData() {
        UserDefaults.standard.removeObject(forKey: "selectedMortgageTypes")
        financialInstitutions = []
        loadFinancialInstitutions()
        loadSelectedMortgageTypes()
    }

    func toggleBankExpansion(_ bankId: UUID) {
        if expandedBanks.contains(bankId) {
            expandedBanks.remove(bankId)
        } else {
            expandedBanks.insert(bankId)
        }
    }

    func toggleMortgageTypeSelection(for bankId: UUID, mortgageType: String) {
        if let index = financialInstitutions.firstIndex(where: { $0.id == bankId }) {
            if financialInstitutions[index].selectedMortgageTypes.contains(mortgageType) {
                financialInstitutions[index].selectedMortgageTypes.remove(mortgageType)
            } else {
                financialInstitutions[index].selectedMortgageTypes.insert(mortgageType)
            }
            saveSelectedMortgageTypes()
        }
    }

    func isMortgageTypeSelected(for bankId: UUID, mortgageType: String) -> Bool {
        guard let bank = financialInstitutions.first(where: { $0.id == bankId }) else {
            return false
        }
        return bank.selectedMortgageTypes.contains(mortgageType)
    }

    func selectAllMortgageTypes(for bankId: UUID) {
        if let index = financialInstitutions.firstIndex(where: { $0.id == bankId }) {
            financialInstitutions[index].selectedMortgageTypes = Set(financialInstitutions[index].mortgageTypes)
            saveSelectedMortgageTypes()
        }
    }

    func deselectAllMortgageTypes(for bankId: UUID) {
        if let index = financialInstitutions.firstIndex(where: { $0.id == bankId }) {
            financialInstitutions[index].selectedMortgageTypes.removeAll()
            saveSelectedMortgageTypes()
        }
    }

    func areAllMortgageTypesSelected(for bankId: UUID) -> Bool {
        guard let bank = financialInstitutions.first(where: { $0.id == bankId }) else {
            return false
        }
        return bank.selectedMortgageTypes.count == bank.mortgageTypes.count
    }

    func areNoMortgageTypesSelected(for bankId: UUID) -> Bool {
        guard let bank = financialInstitutions.first(where: { $0.id == bankId }) else {
            return true
        }
        return bank.selectedMortgageTypes.isEmpty
    }

    private func saveSelectedMortgageTypes() {
        var selections: [String: [String]] = [:]
        for institution in financialInstitutions {
            selections[institution.name] = Array(institution.selectedMortgageTypes)
        }
        UserDefaults.standard.set(selections, forKey: "selectedMortgageTypes")
    }

    private func loadSelectedMortgageTypes() {
        guard let selections = UserDefaults.standard.dictionary(forKey: "selectedMortgageTypes") as? [String: [String]] else {
            return
        }

        for i in 0..<financialInstitutions.count {
            if let bankSelections = selections[financialInstitutions[i].name] {
                financialInstitutions[i].selectedMortgageTypes = Set(bankSelections)
            }
        }
    }

    func updateLoanParameters(_ newParameters: LoanParameters) {
        print("Updating loan parameters: \(newParameters)")
        loanParameters = newParameters
        saveLoanParameters()
        print("Parameters updated and saved")
    }

    private func saveLoanParameters() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(loanParameters) {
            UserDefaults.standard.set(data, forKey: "loanParameters")
        }
    }

    private func loadLoanParameters() {
        guard let data = UserDefaults.standard.data(forKey: "loanParameters"),
              let savedParameters = try? JSONDecoder().decode(LoanParameters.self, from: data) else {
            return
        }
        loanParameters = savedParameters
    }
}
