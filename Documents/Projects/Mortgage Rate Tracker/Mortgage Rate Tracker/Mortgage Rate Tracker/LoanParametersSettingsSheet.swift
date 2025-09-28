import SwiftUI

struct LoanParametersSettingsSheet: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @Binding var isPresented: Bool
    @State private var purchasePriceText: String = ""
    @State private var downPaymentText: String = ""
    @State private var zipCodeText: String = ""
    @State private var showingValidationError = false
    @State private var validationMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Loan Details")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Purchase Price")
                            .font(.headline)
                        TextField("$250,000", text: $purchasePriceText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Down Payment")
                            .font(.headline)
                        TextField("$50,000", text: $downPaymentText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ZIP Code")
                            .font(.headline)
                        TextField("95464", text: $zipCodeText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }

                Section(header: Text("Calculated")) {
                    let cleanPurchasePrice = purchasePriceText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                    let cleanDownPayment = downPaymentText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")

                    if let purchasePrice = Int(cleanPurchasePrice),
                       let downPayment = Int(cleanDownPayment),
                       purchasePrice > 0 {
                        let loanAmount = purchasePrice - downPayment
                        let downPaymentPercent = Double(downPayment) / Double(purchasePrice) * 100

                        HStack {
                            Text("Loan Amount:")
                            Spacer()
                            Text(loanAmount.formattedAsCurrency)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Down Payment %:")
                            Spacer()
                            Text(downPaymentPercent.formattedAsPercentage)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .navigationTitle("Loan Parameters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveParameters()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Invalid Parameters", isPresented: $showingValidationError) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
        }
        .onAppear {
            loadCurrentParameters()
        }
    }

    private func loadCurrentParameters() {
        purchasePriceText = String(settingsViewModel.loanParameters.purchasePrice)
        downPaymentText = String(settingsViewModel.loanParameters.downPayment)
        zipCodeText = settingsViewModel.loanParameters.zipCode
    }

    private func saveParameters() {
        let cleanPurchasePrice = purchasePriceText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        let cleanDownPayment = downPaymentText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")

        print("Saving parameters - Purchase: '\(purchasePriceText)' -> '\(cleanPurchasePrice)', Down: '\(downPaymentText)' -> '\(cleanDownPayment)', ZIP: '\(zipCodeText)'")

        guard let purchasePrice = Int(cleanPurchasePrice),
              let downPayment = Int(cleanDownPayment) else {
            print("Failed to parse numbers")
            showValidationError("Please enter valid numbers for purchase price and down payment.")
            return
        }

        guard purchasePrice > 0 else {
            print("Purchase price not > 0")
            showValidationError("Purchase price must be greater than 0.")
            return
        }

        guard zipCodeText.count == 5 && zipCodeText.allSatisfy({ $0.isNumber }) else {
            print("Invalid ZIP code")
            showValidationError("Please enter a valid 5-digit ZIP code.")
            return
        }

        let newParameters = LoanParameters(
            purchasePrice: purchasePrice,
            downPayment: downPayment,
            zipCode: zipCodeText
        )

        print("Creating new parameters: \(newParameters)")
        settingsViewModel.updateLoanParameters(newParameters)
        isPresented = false
    }

    private func showValidationError(_ message: String) {
        validationMessage = message
        showingValidationError = true
    }

}