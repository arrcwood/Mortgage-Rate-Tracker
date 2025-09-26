
import Foundation
import Combine
import SwiftSoup
import SwiftData

class MortgageRateFetcher: ObservableObject {
    @Published var rates: [MortgageRate] = []
    var modelContext: ModelContext?

    private var lastFetchDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastFetchDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastFetchDate") }
    }

    init(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }

    func fetchData() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "EST")!
        let now = Date()
        let noonToday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!

        if let lastFetch = lastFetchDate, lastFetch > noonToday && calendar.isDateInToday(lastFetch) {
            // Already fetched today after noon
            return
        }
        
        if now < noonToday && lastFetchDate != nil && calendar.isDateInToday(lastFetchDate!) {
            // It's before noon, but we already fetched today
            return
        }

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
                self.lastFetchDate = Date()
            }
        }.resume()
    }

    func parse(html: String) {
        var newRates: [MortgageRate] = []
        do {
            let doc: Document = try SwiftSoup.parse(html)
            let rateTables = try doc.select("div.ratesTable")
            for rateTable in rateTables {
                if let h2 = try rateTable.select("h2").first(), try h2.text().contains("VA Loan Rates") {
                    let rows = try rateTable.select("tbody tr")
                    for row in rows {
                        let th = try row.select("th").first()
                        let tds = try row.select("td")
                        if let th = th, tds.count >= 3 {
                            let loanType = try th.text()
                            let interestRate = try tds[0].text()
                            let discountPoints = try tds[1].text()
                            let apr = try tds[2].text()

                            let rate = MortgageRate(loanType: loanType, interestRate: interestRate, discountPoints: discountPoints, apr: apr)
                            newRates.append(rate)

                            let record = RateRecord(date: Date(), loanType: loanType, interestRate: interestRate, apr: apr)
                            modelContext?.insert(record)
                        }
                    }
                }
            }
            self.rates = newRates
        } catch Exception.Error(let type, let message) {
            print("Message: \(message) Type: \(type)")
        } catch {
            print("error")
        }
    }
}
