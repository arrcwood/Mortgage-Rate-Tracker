
import SwiftUI

struct ContentView: View {
    @StateObject private var fetcher = MortgageRateFetcher()

    var body: some View {
        NavigationView {
            List(fetcher.rates) { rate in
                VStack(alignment: .leading) {
                    Text(rate.loanType)
                        .font(.headline)
                    Text("Interest Rate: \(rate.interestRate)")
                    Text("Discount Points: \(rate.discountPoints)")
                    Text("APR: \(rate.apr)")
                }
            }
            .navigationTitle("Mortgage Rates")
            .toolbar {
                Button("Refresh") {
                    fetcher.fetchData()
                }
            }
            .onAppear {
                fetcher.fetchData()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
