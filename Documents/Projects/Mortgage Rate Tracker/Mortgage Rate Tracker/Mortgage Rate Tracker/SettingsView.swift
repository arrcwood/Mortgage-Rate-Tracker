
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            Section(header: Text("Financial Institutions")) {
                ForEach(viewModel.financialInstitutions) { institution in
                    NavigationLink(destination: FinancialInstitutionDetailView(institution: institution)) {
                        Text(institution.name)
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
