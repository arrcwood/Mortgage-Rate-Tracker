
import SwiftUI

struct FinancialInstitutionDetailView: View {
    let institution: FinancialInstitution

    var body: some View {
        List {
            Text("This is the detail view for \(institution.name)")
        }
        .navigationTitle(institution.name)
    }
}
