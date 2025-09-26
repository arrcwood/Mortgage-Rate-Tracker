import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var fetcher: MortgageRateFetcher
    @Query(sort: \.date, order: .reverse) private var rateRecords: [RateRecord]
    @Environment(\.modelContext) private var modelContext

    private var groupedRecords: [Date: [RateRecord]] {
        Dictionary(grouping: rateRecords) { record in
            Calendar.current.startOfDay(for: record.date)
        }
    }

    private var sortedGroupedDates: [Date] {
        groupedRecords.keys.sorted().reversed()
    }

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

                List(sortedGroupedDates, id: \.self) { date in
                    HStack(alignment: .center) {
                        Text(date, formatter: dateFormatter)
                            .font(.footnote)

                        VStack(alignment: .leading) {
                            if let record15 = groupedRecords[date]?.first(where: { $0.loanType.contains("15") }) {
                                Text("15 Year: \(record15.interestRate) / \(record15.apr)")
                                    .font(.footnote)
                            }
                            if let record30 = groupedRecords[date]?.first(where: { $0.loanType.contains("30") }) {
                                Text("30 Year: \(record30.interestRate) / \(record30.apr)")
                                    .font(.footnote)
                            }
                        }
                        .padding(.leading)
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

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
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