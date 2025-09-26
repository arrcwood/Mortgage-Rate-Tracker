import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var fetcher: MortgageRateFetcher
    @Query private var rateRecords: [RateRecord]
    @Environment(\.modelContext) private var modelContext

    init() {
        _fetcher = State(initialValue: MortgageRateFetcher(modelContext: nil))
    }

    var body: some View {
        NavigationView {
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

                Spacer()

                List(rateRecords) { record in
                    VStack(alignment: .leading) {
                        Text(record.date, style: .date)
                        Text("\(record.loanType): \(record.interestRate) / \(record.apr)")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        fetcher.fetchData()
                    }
                }
            }
            .onAppear {
                fetcher.modelContext = modelContext
                fetcher.fetchData()
            }
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