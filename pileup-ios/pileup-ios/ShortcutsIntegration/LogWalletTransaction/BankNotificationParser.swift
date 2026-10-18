import Foundation
import CoreML

/// Result of parsing an expense transaction notification.
public struct ParsedBankNotification {
    /// The parsed monetary amount
    public let amount: Double
    /// The merchant name, used as transaction description/title
    public let merchant: String
    /// The account/bank provider (can be nil if not present or unidentified)
    public let paymentProvider: String?
    
    public init(amount: Double, merchant: String, paymentProvider: String? = nil) {
        self.amount = amount
        self.merchant = merchant
        self.paymentProvider = paymentProvider
    }
}

/// Parser for bank notifications and SMS alerts using CoreML Word Tagger.
public final class BankNotificationParser {
    public static let shared = BankNotificationParser()
    
    /// Compiled CoreML Word Tagger model loaded from the app bundle
    private var model: MLModel?
    
    private init() {
        loadModel()
    }
    
    /// Loads the trained CoreML model from the bundle if present
    private func loadModel() {
        if let modelURL = Bundle.main.url(forResource: "BankNotificationWordTagger", withExtension: "mlmodelc") {
            self.model = try? MLModel(contentsOf: modelURL)
        }
    }
    
    // MARK: - Main Parsing Entry Point
    
    /// Parses an incoming notification or SMS text.
    /// - Parameters:
    ///   - text: The raw text of the message/notification.
    ///   - knownBankName: Optional bank or financial institution if the notification was sent by a specific bank app.
    /// - Returns: ParsedBankNotification or nil if no valid amount or description could be extracted.
    public func parse(text: String, knownBankName: String? = nil) -> ParsedBankNotification? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let cleanBank = knownBankName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasKnownBank = (cleanBank != nil && !cleanBank!.isEmpty)
        
        // Run CoreML model prediction on the text
        guard let prediction = predictWithCoreML(text: trimmed) else {
            return nil
        }
        
        if hasKnownBank {
            // Case 1: Notification from known bank app
            // - The bank is directly used as the account
            // - CoreML provides merchant (as description) and amount
            return ParsedBankNotification(
                amount: prediction.amount,
                merchant: prediction.merchant,
                paymentProvider: cleanBank
            )
        } else {
            // Case 2: Generic raw text / SMS
            // - All fields evaluated by CoreML: amount, merchant (description), and account provider
            // - Provider remains nil if not present in the message
            return ParsedBankNotification(
                amount: prediction.amount,
                merchant: prediction.merchant,
                paymentProvider: prediction.provider
            )
        }
    }
    
    // MARK: - CoreML Prediction
    
    private struct PredictionResult {
        let amount: Double
        let merchant: String
        let provider: String?
    }
    
    /// Evaluates the sentence using the CoreML Word Tagger model.
    /// Extracts tokens tagged with labels: AMOUNT, MERCHANT, PROVIDER.
    private func predictWithCoreML(text: String) -> PredictionResult? {
        guard let model = self.model else {
            // If the .mlmodel has not yet been compiled into the Xcode bundle,
            // return nil until the model file is placed in the project.
            return nil
        }
        
        do {
            let input = try MLDictionaryFeatureProvider(dictionary: ["text": text])
            let output = try model.prediction(from: input)
            
            guard let tokens = output.featureValue(for: "tokens")?.sequenceValue?.stringValues,
                  let labels = output.featureValue(for: "labels")?.sequenceValue?.stringValues,
                  tokens.count == labels.count else {
                return nil
            }
            
            var amountVal: Double?
            var merchantWords: [String] = []
            var providerWords: [String] = []
            
            for (token, label) in zip(tokens, labels) {
                switch label.uppercased() {
                case "AMOUNT":
                    let cleanedNumber = token.replacingOccurrences(of: ",", with: ".")
                    if let val = Double(cleanedNumber), val > 0 {
                        amountVal = val
                    }
                case "MERCHANT":
                    merchantWords.append(token)
                case "PROVIDER":
                    providerWords.append(token)
                default:
                    break
                }
            }
            
            guard let amount = amountVal, !merchantWords.isEmpty else {
                return nil
            }
            
            let merchant = merchantWords.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            let provider = providerWords.isEmpty ? nil : providerWords.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            
            return PredictionResult(
                amount: amount,
                merchant: merchant,
                provider: provider
            )
        } catch {
            return nil
        }
    }
}

