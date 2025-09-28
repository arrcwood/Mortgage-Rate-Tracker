import SwiftUI

struct BankRatesView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @StateObject private var rateFetcher = BankRateFetcher()

    private var banksWithSelectedTypes: [FinancialInstitution] {
        return settingsViewModel.financialInstitutions.filter { institution in
            !institution.selectedMortgageTypes.isEmpty &&
            (settingsViewModel.selectedMortgageTypeFilter == nil ||
             institution.mortgageTypes.contains(settingsViewModel.selectedMortgageTypeFilter!))
        }
    }

    private func getFilteredMortgageTypes(for institution: FinancialInstitution) -> [String] {
        let selectedTypes = institution.mortgageTypes.filter { institution.selectedMortgageTypes.contains($0) }

        if let filter = settingsViewModel.selectedMortgageTypeFilter {
            return selectedTypes.filter { $0 == filter }
        }

        return selectedTypes
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
                        rateFetcher.fetchRatesForSelectedBanks(banksWithSelectedTypes, parameters: settingsViewModel.loanParameters, forceFetch: true)
                    }
                    .disabled(rateFetcher.isLoading || banksWithSelectedTypes.isEmpty)
                }
            }
            .onAppear {
                if !banksWithSelectedTypes.isEmpty && rateFetcher.rates.isEmpty {
                    rateFetcher.fetchRatesForSelectedBanks(banksWithSelectedTypes, parameters: settingsViewModel.loanParameters)
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