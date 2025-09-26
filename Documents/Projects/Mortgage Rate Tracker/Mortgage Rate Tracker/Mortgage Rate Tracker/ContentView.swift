import SwiftUI
import SwiftSoup

// IMPORTANT: To make this code work, you need to add the SwiftSoup package dependency to your project.
// In Xcode, go to File > Add Packages... and enter the following URL: https://github.com/scinfu/SwiftSoup.git

struct MortgageRate: Identifiable {
    let id = UUID()
    let loanType: String
    let interestRate: String
    let discountPoints: String
    let apr: String
}

class MortgageRateFetcher: ObservableObject {
    @Published var rates: [MortgageRate] = []
    
    func fetchData() {
        guard let url = URL(string: "https://www.navyfederal.org/loans-cards/mortgage/mortgage-rates.html") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            let html = String(data: data, encoding: .utf8)!
            
            DispatchQueue.main.async {
                self.parse(html: html)
            }
        }.resume()
    }
    
    func parse(html: String) {
        self.rates.removeAll()
        do {
            let doc: Document = try SwiftSoup.parse(html)
            let tables = try doc.select("table")
            for table in tables {
                let h3 = try table.previousElementSibling()?.select("h3").first()
                if let h3 = h3, try h3.text().contains("VA Loans") {
                    let rows = try table.select("tbody tr")
                    for row in rows {
                        let th = try row.select("th").first()
                        let tds = try row.select("td")
                        if let th = th, tds.count >= 3 {
                            let loanType = try th.text()
                            let interestRate = try tds[0].text()
                            let discountPoints = try tds[1].text()
                            let apr = try tds[2].text()
                            
                            let rate = MortgageRate(loanType: loanType, interestRate: interestRate, discountPoints: discountPoints, apr: apr)
                            self.rates.append(rate)
                        }
                    }
                }
            }
        } catch Exception.Error(let type, let message) {
            print("Message: \(message) Type: \(type)")
        } catch {
            print("error")
        }
    }
}

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