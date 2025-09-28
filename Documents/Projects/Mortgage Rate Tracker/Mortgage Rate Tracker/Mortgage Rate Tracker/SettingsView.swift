
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel

    var body: some View {
        List {
            Section(header: Text("Loan Parameters")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Purchase Price")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(settingsViewModel.loanParameters.purchasePrice.formattedAsCurrency)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Down Payment")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(settingsViewModel.loanParameters.downPayment.formattedAsCurrency)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ZIP Code")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(settingsViewModel.loanParameters.zipCode)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Loan Amount")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(settingsViewModel.loanParameters.loanAmount.formattedAsCurrency)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Edit Loan Parameters") {
                        settingsViewModel.showingParametersSheet = true
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                }
                .padding(.vertical, 8)
            }

            Section(header: Text("Mortgage Types")) {
                VStack(alignment: .leading, spacing: 8) {
                    if settingsViewModel.selectedMortgageTypeFilter != nil {
                        Button(action: {
                            settingsViewModel.clearMortgageTypeFilter()
                        }) {
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(.blue)
                                Text("Show All Types")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                    }

                    ForEach(settingsViewModel.allMortgageTypes, id: \.self) { mortgageType in
                        Button(action: {
                            settingsViewModel.selectMortgageTypeFilter(mortgageType)
                        }) {
                            HStack {
                                Image(systemName: settingsViewModel.selectedMortgageTypeFilter == mortgageType ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(settingsViewModel.selectedMortgageTypeFilter == mortgageType ? .blue : .secondary)
                                Text(mortgageType)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                    }

                    if settingsViewModel.selectedMortgageTypeFilter != nil {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Showing institutions that offer: \(settingsViewModel.selectedMortgageTypeFilter!)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 4)
            }

            Section(header: HStack {
                Text("Financial Institutions")
                Spacer()
                Button("Debug") {
                    settingsViewModel.clearCachedData()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }) {
                ForEach(settingsViewModel.financialInstitutions) { institution in
                    VStack(alignment: .leading) {
                        Button(action: {
                            settingsViewModel.toggleBankExpansion(institution.id)
                        }) {
                            HStack {
                                Text(institution.name)
                                    .foregroundColor(.primary)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: settingsViewModel.expandedBanks.contains(institution.id) ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        if settingsViewModel.expandedBanks.contains(institution.id) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mortgage Types:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)

                                HStack(spacing: 16) {
                                    Button(action: {
                                        settingsViewModel.selectAllMortgageTypes(for: institution.id)
                                    }) {
                                        Text("Select All")
                                            .font(.caption)
                                            .foregroundColor(settingsViewModel.areAllMortgageTypesSelected(for: institution.id) ? .gray : .blue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(settingsViewModel.areAllMortgageTypesSelected(for: institution.id))

                                    Button(action: {
                                        settingsViewModel.deselectAllMortgageTypes(for: institution.id)
                                    }) {
                                        Text("Deselect All")
                                            .font(.caption)
                                            .foregroundColor(settingsViewModel.areNoMortgageTypesSelected(for: institution.id) ? .gray : .red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(settingsViewModel.areNoMortgageTypesSelected(for: institution.id))

                                    Spacer()
                                }

                                ForEach(Array(institution.mortgageTypes.enumerated()), id: \.offset) { index, mortgageType in
                                    HStack {
                                        Button(action: {
                                            settingsViewModel.toggleMortgageTypeSelection(for: institution.id, mortgageType: mortgageType)
                                        }) {
                                            HStack {
                                                Image(systemName: settingsViewModel.isMortgageTypeSelected(for: institution.id, mortgageType: mortgageType) ? "checkmark.square.fill" : "square")
                                                    .foregroundColor(settingsViewModel.isMortgageTypeSelected(for: institution.id, mortgageType: mortgageType) ? .blue : .secondary)
                                                Text(mortgageType)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.leading, 16)
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .sheet(isPresented: $settingsViewModel.showingParametersSheet) {
            LoanParametersSettingsSheet(settingsViewModel: settingsViewModel, isPresented: $settingsViewModel.showingParametersSheet)
        }
        .onAppear {
            settingsViewModel.refreshData()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settingsViewModel: SettingsViewModel())
    }
}
