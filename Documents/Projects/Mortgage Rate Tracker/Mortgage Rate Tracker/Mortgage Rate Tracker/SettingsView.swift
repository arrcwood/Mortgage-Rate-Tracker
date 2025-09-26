
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.financialInstitutions) { institution in
                VStack(alignment: .leading) {
                    Text(institution.name)
                        .font(.headline)
                    ForEach(institution.website, id: \.self) { website in
                        Link(website, destination: URL(string: website)!)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Financial Institutions")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
