
import SwiftUI

struct FinancialInstitutionDetailView: View {
    let institution: FinancialInstitution

    var body: some View {
        List(institution.website, id: \.self) { website in
            Link(website, destination: URL(string: website)!)
        }
        .navigationTitle(institution.name)
    }
}
