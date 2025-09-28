import SwiftUI

struct BankRatesView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @StateObject private var rateFetcher = BankRateFetcher()

    private var banksWithSelectedTypes: [FinancialInstitution] {
        if let filter = settingsViewModel.selectedMortgageTypeFilter {
            // When a mortgage type filter is selected, show all banks that offer that type
            return settingsViewModel.financialInstitutions.filter { institution in
                institution.mortgageTypes.contains(filter)
            }
        } else {
            // When no filter is selected, show banks with selected mortgage types
            return settingsViewModel.financialInstitutions.filter { institution in
                !institution.selectedMortgageTypes.isEmpty
            }
        }
    }

    private func getFilteredMortgageTypes(for institution: FinancialInstitution) -> [String] {
        if let filter = settingsViewModel.selectedMortgageTypeFilter {
            // When filtering, show only the filtered type (regardless of user selection)
            return institution.mortgageTypes.contains(filter) ? [filter] : []
        } else {
            // When not filtering, show only user-selected types
            return institution.mortgageTypes.filter { institution.selectedMortgageTypes.contains($0) }
        }
    }

    private func getInstitutionsForFetching() -> [FinancialInstitution] {
        if let filter = settingsViewModel.selectedMortgageTypeFilter {
            // When filtering by mortgage type, modify institutions to have that type selected
            return banksWithSelectedTypes.map { institution in
                var modifiedInstitution = institution
                modifiedInstitution.selectedMortgageTypes = [filter]
                return modifiedInstitution
            }
        } else {
            // When not filtering, use institutions as they are
            return banksWithSelectedTypes
        }
    }

    var body: some View {
        NavigationView {
            List {
                if banksWithSelectedTypes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.square")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No Mortgage Types Selected")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Go to Settings to select which mortgage types you want to track from each bank.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(banksWithSelectedTypes) { institution in
                        Section(header: HStack {
                            Text(institution.name).font(.headline)
                            Spacer()
                            if rateFetcher.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }) {
                            ForEach(getFilteredMortgageTypes(for: institution), id: \.self) { mortgageType in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(mortgageType)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(institution.fields, id: \.name) { field in
                                            HStack {
                                                Text("\(field.label):")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                if let bankRates = rateFetcher.rates[institution.name],
                                                   let rate = bankRates.first(where: { $0.mortgageType == mortgageType }) {
                                                    Text(getFieldValue(for: field.name, from: rate))
                                                        .font(.caption)
                                                        .foregroundColor(.primary)
                                                } else {
                                                    Text("--")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bank Rates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fetch Rates") {
                        let institutionsToFetch = getInstitutionsForFetching()
                        rateFetcher.fetchRatesForSelectedBanks(institutionsToFetch, parameters: settingsViewModel.loanParameters, forceFetch: true)
                    }
                    .disabled(rateFetcher.isLoading || banksWithSelectedTypes.isEmpty)
                }
            }
            .onAppear {
                if !banksWithSelectedTypes.isEmpty && rateFetcher.rates.isEmpty {
                    let institutionsToFetch = getInstitutionsForFetching()
                    rateFetcher.fetchRatesForSelectedBanks(institutionsToFetch, parameters: settingsViewModel.loanParameters)
                }
            }
        }
    }

    private func getFieldValue(for fieldName: String, from rate: BankRate) -> String {
        let value: String
        switch fieldName {
        case "interestRate":
            value = rate.interestRate
        case "apr":
            value = rate.apr
        case "points":
            value = rate.points
        default:
            return "-"
        }

        // Return "-" if the value is "N/A", empty, or not a valid number/percentage
        if value == "N/A" || value.isEmpty {
            return "-"
        }

        // Check if it's a valid number, percentage, or dollar amount
        let cleanValue = value.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        if cleanValue.isEmpty || (!cleanValue.contains(".") && Double(cleanValue) == nil) && Double(cleanValue) == nil {
            return "-"
        }

        return value
    }
}

struct BankRatesView_Previews: PreviewProvider {
    static var previews: some View {
        BankRatesView(settingsViewModel: SettingsViewModel())
    }
}