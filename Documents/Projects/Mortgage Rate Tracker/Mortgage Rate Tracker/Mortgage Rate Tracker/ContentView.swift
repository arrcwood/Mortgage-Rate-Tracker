import SwiftUI

struct ContentView: View {
    @StateObject private var fetcher = MortgageRateFetcher()

    var body: some View {
        VStack {
            Text("Mortgage Rate Tracker")
                .font(.largeTitle)
                .padding()

            Grid {
                GridRow {
                    Text("Term").font(.headline)
                    Text("Interest Rate").font(.headline)
                    Text("APR").font(.headline)
                }
                GridRow {
                    Text("15 year")
                    Text(rateFor(term: "15")?.interestRate ?? "N/A")
                    Text(rateFor(term: "15")?.apr ?? "N/A")
                }
                GridRow {
                    Text("30 year")
                    Text(rateFor(term: "30")?.interestRate ?? "N/A")
                    Text(rateFor(term: "30")?.apr ?? "N/A")
                }
            }
            .padding()

            Button("Refresh") {
                fetcher.fetchData()
            }
            .padding()
        }
        .onAppear {
            fetcher.fetchData()
        }
    }

    private func rateFor(term: String) -> MortgageRate? {
        return fetcher.rates.first { $0.loanType.contains(term) }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}