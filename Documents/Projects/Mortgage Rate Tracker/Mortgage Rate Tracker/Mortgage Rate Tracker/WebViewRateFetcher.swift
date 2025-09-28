import Foundation
import WebKit
import SwiftUI
import Combine

class WebViewRateFetcher: NSObject, ObservableObject {
    private var webView: WKWebView?
    private var completion: ((Result<[BankRate], Error>) -> Void)?
    private var currentInstitution: FinancialInstitution?
    private var currentParameters: LoanParameters?

    override init() {
        super.init()
        setupWebView()
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
    }

    func fetchRates(for institution: FinancialInstitution, parameters: LoanParameters) -> Future<[BankRate], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(URLError(.unknown)))
                return
            }

            self.currentInstitution = institution
            self.currentParameters = parameters
            self.completion = promise

            guard let url = URL(string: institution.url) else {
                promise(.failure(URLError(.badURL)))
                return
            }

            print("WebView loading Bank of America page: \(url)")
            let request = URLRequest(url: url)
            self.webView?.load(request)
        }
    }

    private func fillFormAndExtractRates() {
        guard let institution = currentInstitution,
              let parameters = currentParameters else {
            completion?(.failure(URLError(.unknown)))
            return
        }

        print("Filling form with: Purchase=\(parameters.purchasePrice), Down=\(parameters.downPayment), ZIP=\(parameters.zipCode)")

        let fillJS: String

        // Handle different banks with different form structures
        switch institution.name {
        case "Chase":
            fillJS = fillChaseForm(parameters: parameters)
        case "Bank of America":
            fillJS = fillBankOfAmericaForm(parameters: parameters)
        default:
            completion?(.failure(URLError(.unsupportedURL)))
            return
        }

        webView?.evaluateJavaScript(fillJS) { [weak self] result, error in
            if let error = error {
                print("JavaScript error: \(error)")
                self?.completion?(.failure(error))
                return
            }

            print("Form filled successfully")

            // Wait a moment for the page to update, then extract rates
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self?.extractRates()
            }
        }
    }

    private func fillChaseForm(parameters: LoanParameters) -> String {
        return """
        (function() {
            console.log('Filling Chase form with ZIP: \(parameters.zipCode)');

            // Look for the ZIP code input field using various selectors
            let zipField = document.querySelector('input[name="ZIP code"]') ||
                          document.querySelector('input[aria-label="ZIP code"]') ||
                          document.querySelector('input[pattern="[0-9]{5}"]') ||
                          document.querySelector('input[maxlength="5"]') ||
                          document.querySelector('input[autocomplete="postal-code"]');

            if (zipField) {
                zipField.value = '\(parameters.zipCode)';
                zipField.focus();

                // Trigger input events
                zipField.dispatchEvent(new Event('input', { bubbles: true }));
                zipField.dispatchEvent(new Event('change', { bubbles: true }));
                zipField.dispatchEvent(new Event('blur', { bubbles: true }));

                console.log('Filled ZIP code:', zipField.value);

                // Wait a moment, then click the "See Rates" button
                setTimeout(function() {
                    let seeRatesButton = document.querySelector('button[data-pt-name="sm_next"]') ||
                                        document.querySelector('button:contains("See Rates")') ||
                                        document.querySelector('button .btn-primary-button-text:contains("See Rates")');

                    if (seeRatesButton) {
                        console.log('Clicking See Rates button');
                        seeRatesButton.click();
                    } else {
                        console.log('See Rates button not found');
                    }
                }, 1000);

                return 'SUCCESS';
            } else {
                console.log('ZIP code field not found');
                return 'ERROR: ZIP field not found';
            }
        })();
        """
    }

    private func fillBankOfAmericaForm(parameters: LoanParameters) -> String {
        return """
        (function() {
            console.log('Filling Bank of America form...');

            // Bank of America form filling logic (existing)
            function triggerChange(element) {
                const events = ['input', 'change', 'blur'];
                events.forEach(eventType => {
                    const event = new Event(eventType, { bubbles: true });
                    element.dispatchEvent(event);
                });
            }

            try {
                let filledCount = 0;

                const purchaseField = document.querySelector('#purchase-price-input-medium');
                if (purchaseField) {
                    purchaseField.value = '\(parameters.purchasePrice)';
                    purchaseField.focus();
                    triggerChange(purchaseField);
                    filledCount++;
                }

                const downField = document.querySelector('#down-payment-input-medium');
                if (downField) {
                    downField.value = '\(parameters.downPayment)';
                    downField.focus();
                    triggerChange(downField);
                    filledCount++;
                }

                const zipField = document.querySelector('#zip-code-input-medium');
                if (zipField) {
                    zipField.value = '\(parameters.zipCode)';
                    zipField.focus();
                    triggerChange(zipField);
                    filledCount++;
                }

                const updateButton = document.querySelector('#update-button-medium, [id*="update"], button:contains("Update"), button:contains("Calculate")');
                if (updateButton) {
                    updateButton.click();
                    console.log('Clicked update button');
                }

                return 'FILLED_' + filledCount + '_FIELDS';
            } catch (error) {
                console.error('Error filling form:', error);
                return 'ERROR: ' + error.message;
            }
        })();
        """
    }

    private func extractChaseRates() -> String {
        return """
        (function() {
            console.log('Starting Chase rate extraction...');

            const rates = [];

            // Chase bank specific extraction - look for table rows
            const tableRows = document.querySelectorAll('tr');
            console.log('Found', tableRows.length, 'table rows');

            for (let i = 0; i < tableRows.length; i++) {
                const row = tableRows[i];
                const rowText = row.textContent.trim();

                // Skip header rows and empty rows
                if (!rowText || rowText.includes('Product') || rowText.includes('Interest Rate') || rowText.includes('APR')) {
                    continue;
                }

                // Look for rows that contain mortgage product names
                if (rowText.includes('Fixed') || rowText.includes('FHA') || rowText.includes('ARM') || rowText.includes('Jumbo')) {
                    const cells = row.querySelectorAll('td');

                    if (cells.length >= 3) {
                        const productName = cells[0].textContent.trim();
                        const interestRate = cells[1].textContent.trim();
                        const apr = cells[2].textContent.trim();

                        console.log('Found Chase rate:', { productName, interestRate, apr });

                        rates.push({
                            productName: productName,
                            interestRate: interestRate,
                            apr: apr,
                            points: 'N/A'  // Chase doesn't display points in the basic table
                        });
                    }
                }
            }

            // If no table structure, try alternative approach
            if (rates.length === 0) {
                console.log('No table structure found, trying percentage-based extraction...');

                // Look for elements containing percentage signs
                const percentElements = document.querySelectorAll('*');
                let foundRates = [];

                percentElements.forEach(el => {
                    if (el.textContent && el.textContent.includes('%')) {
                        const text = el.textContent.trim();
                        // Match patterns like "6.125%" or "6.213%"
                        const rateMatch = text.match(/\\d+\\.\\d+%/);
                        if (rateMatch) {
                            foundRates.push({
                                element: el,
                                rate: rateMatch[0],
                                context: text.substring(0, 50)
                            });
                        }
                    }
                });

                console.log('Found percentage elements:', foundRates.length);
                return { rates: [], debug: { percentages: foundRates.slice(0, 10) } };
            }

            console.log('Chase extraction completed, found', rates.length, 'rates');
            return { rates: rates, debug: 'Chase Success' };
        })();
        """
    }

    private func extractBankOfAmericaRates() -> String {
        return """
        (function() {
            console.log('Starting Bank of America rate extraction...');

            const rates = [];

            // Look for rate rows using multiple selectors
            const selectors = [
                'div.row[data-product-name]',
                '[data-product-name]',
                '.row[data-product-name]',
                '.mortgage-rate-row',
                '.rate-row',
                'tr[data-product-name]'
            ];

            let rows = [];
            for (const selector of selectors) {
                rows = document.querySelectorAll(selector);
                if (rows.length > 0) {
                    console.log('Found', rows.length, 'rows with selector:', selector);
                    break;
                }
            }

            if (rows.length === 0) {
                console.log('No rate rows found, trying alternative approach...');
                // Look for table rows that might contain rates
                const tableRows = document.querySelectorAll('tr');
                console.log('Found', tableRows.length, 'table rows total');

                // Look for any elements containing percentage signs
                const percentElements = document.querySelectorAll('*');
                let foundRates = [];
                let ratePatterns = [];
                percentElements.forEach(el => {
                    if (el.textContent && el.textContent.includes('%')) {
                        const text = el.textContent.trim();
                        if (text.match(/\\d+\\.\\d+%/)) {
                            foundRates.push(text);
                            // Try to find parent elements that might contain full rate info
                            let parent = el.parentElement;
                            while (parent && parent !== document.body) {
                                if (parent.textContent.includes('Fixed') || parent.textContent.includes('ARM')) {
                                    ratePatterns.push({
                                        rate: text,
                                        context: parent.textContent.trim().substring(0, 100)
                                    });
                                    break;
                                }
                                parent = parent.parentElement;
                            }
                        }
                    }
                });
                console.log('Found elements with percentages:', foundRates.slice(0, 10));
                console.log('Found rate patterns:', ratePatterns.slice(0, 5));
                return { rates: [], debug: { percentages: foundRates.slice(0, 10), patterns: ratePatterns.slice(0, 5) } };
            }

            rows.forEach((row, index) => {
                try {
                    const productName = row.getAttribute('data-product-name') || 'Unknown';
                    console.log('Processing row', index, 'product:', productName);

                    // Extract rate data with more flexible selectors
                    const rateSelectors = [
                        'p.partial-rate span.update-partial',
                        '.partial-rate .update-partial',
                        '[class*="rate"] [class*="update"]',
                        '.rate-value',
                        '.interest-rate'
                    ];

                    const aprSelectors = [
                        'p.partial-apr span.update-partial',
                        '.partial-apr .update-partial',
                        '[class*="apr"] [class*="update"]',
                        '.apr-value'
                    ];

                    const pointsSelectors = [
                        'p.partial-points span.update-partial',
                        '.partial-points .update-partial',
                        '[class*="points"] [class*="update"]',
                        '.points-value'
                    ];

                    let rate = 'N/A', apr = 'N/A', points = 'N/A';

                    for (const selector of rateSelectors) {
                        const element = row.querySelector(selector);
                        if (element && element.textContent.trim()) {
                            rate = element.textContent.trim();
                            break;
                        }
                    }

                    for (const selector of aprSelectors) {
                        const element = row.querySelector(selector);
                        if (element && element.textContent.trim()) {
                            apr = element.textContent.trim();
                            break;
                        }
                    }

                    for (const selector of pointsSelectors) {
                        const element = row.querySelector(selector);
                        if (element && element.textContent.trim()) {
                            points = element.textContent.trim();
                            break;
                        }
                    }

                    console.log('Extracted:', { productName, rate, apr, points });

                    if (rate !== 'N/A' || apr !== 'N/A' || points !== 'N/A') {
                        rates.push({
                            productName: productName,
                            interestRate: rate,
                            apr: apr,
                            points: points
                        });
                    }
                } catch (error) {
                    console.error('Error processing row:', error);
                }
            });

            console.log('Total rates extracted:', rates.length);
            return { rates: rates, debug: 'Bank of America Success' };
        })();
        """
    }

    private func extractRates() {
        guard let institution = currentInstitution else {
            completion?(.failure(URLError(.unknown)))
            return
        }

        let extractionJavaScript: String

        // Use different extraction logic based on the bank
        switch institution.name {
        case "Chase":
            extractionJavaScript = extractChaseRates()
        case "Bank of America":
            extractionJavaScript = extractBankOfAmericaRates()
        default:
            extractionJavaScript = extractBankOfAmericaRates() // Default to BoA approach
        }

        webView?.evaluateJavaScript(extractionJavaScript) { [weak self] result, error in
            if let error = error {
                print("Rate extraction error: \(error)")
                self?.completion?(.failure(error))
                return
            }

            guard let resultDict = result as? [String: Any] else {
                print("Failed to parse extraction result as dictionary: \(String(describing: result))")
                self?.completion?(.failure(URLError(.cannotParseResponse)))
                return
            }

            if let debugInfo = resultDict["debug"] {
                print("Rate extraction debug info: \(debugInfo)")
            }

            guard let ratesData = resultDict["rates"] as? [[String: String]] else {
                print("No rates array found in result")
                // If no rates found, create empty array but don't fail - may be a page loading issue
                self?.completion?(.success([]))
                return
            }

            print("Extracted \(ratesData.count) rates from WebView")

            var bankRates: [BankRate] = []

            for rateData in ratesData {
                guard let productName = rateData["productName"],
                      let interestRate = rateData["interestRate"],
                      let apr = rateData["apr"],
                      let points = rateData["points"] else {
                    print("Skipping incomplete rate data: \(rateData)")
                    continue
                }

                let mappedMortgageType: String
                if let institution = self?.currentInstitution {
                    switch institution.name {
                    case "Chase":
                        mappedMortgageType = self?.mapChaseProductName(productName) ?? productName
                    case "Bank of America":
                        mappedMortgageType = self?.mapBankOfAmericaProductName(productName) ?? productName
                    default:
                        mappedMortgageType = productName
                    }
                } else {
                    mappedMortgageType = productName
                }

                // Only include if the user selected this mortgage type
                if let institution = self?.currentInstitution,
                   institution.selectedMortgageTypes.contains(mappedMortgageType) {
                    let bankRate = BankRate(
                        bankName: institution.name,
                        mortgageType: mappedMortgageType,
                        interestRate: interestRate,
                        apr: apr,
                        points: points,
                        fetchDate: Date()
                    )
                    bankRates.append(bankRate)
                    print("Added rate for \(mappedMortgageType): \(interestRate)")
                } else {
                    print("Skipping unselected mortgage type: \(mappedMortgageType)")
                }
            }

            print("Filtered to \(bankRates.count) selected rates")
            self?.completion?(.success(bankRates))
        }
    }

    private func mapChaseProductName(_ productName: String) -> String {
        // Chase product names should already match bankRates.json format
        // but provide mapping for any variations found on their website
        switch productName {
        case "30 Year Fixed", "30-Year Fixed Rate":
            return "30-year Fixed"
        case "30 Year FHA", "30-Year FHA":
            return "30-year FHA"
        case "15 Year Fixed", "15-Year Fixed Rate":
            return "15-year Fixed"
        case "7/6 ARM", "7/6-Month ARM":
            return "7/6-month ARM"
        case "5/6 ARM", "5/6-Month ARM":
            return "5/6-month ARM"
        case "30 Year Jumbo", "30-Year Jumbo":
            return "30-year Jumbo"
        case "10/6 Interest Only ARM", "10/6 IO Jumbo ARM":
            return "10/6 Interest Only Jumbo ARM"
        default:
            return productName
        }
    }

    private func mapBankOfAmericaProductName(_ productName: String) -> String {
        switch productName {
        case "Fixed 30 Years":
            return "30-year fixed"
        case "Fixed 20 Years":
            return "20-year fixed"
        case "Fixed 15 Years":
            return "15-year fixed"
        case "ARM Fixed First 10 Years, Then Adjusts Every 6 Months":
            return "10-year/6-month ARM variable"
        case "ARM Fixed First 7 Years, Then Adjusts Every 6 Months":
            return "7-year/6-month ARM variable"
        case "ARM Fixed First 5 Years, Then Adjusts Every 6 Months":
            return "5-year/6-month ARM variable"
        default:
            return productName
        }
    }
}

extension WebViewRateFetcher: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading page")

        // Wait a moment for any JavaScript to execute, then fill the form
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.fillFormAndExtractRates()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error)")
        completion?(.failure(error))
    }
}