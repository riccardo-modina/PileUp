import Foundation
import CreateML
import CoreML

let jsonURL = URL(fileURLWithPath: "/Users/riccardomodina/src/PileUp/pileup-ios/ML/data/bank_notifications_training.json")
let outputURL = URL(fileURLWithPath: "/Users/riccardomodina/src/PileUp/pileup-ios/ML/model/BankNotificationWordTagger.mlmodel")

print("1. Loading training data from \(jsonURL.path)...")
do {
    let dataTable = try MLDataTable(contentsOf: jsonURL)
    print("   Parsed \(dataTable.size.rows) training examples.")
    
    print("2. Training MLWordTagger with CRF...")
    let tagger = try MLWordTagger(
        trainingData: dataTable,
        tokenColumn: "tokens",
        labelColumn: "labels"
    )
    
    let metadata = MLModelMetadata(
        author: "PileUp",
        shortDescription: "Trained Word Tagger to extract AMOUNT, MERCHANT, and PROVIDER from bank notifications and SMS.",
        version: "1.0"
    )
    
    print("3. Saving CoreML model to \(outputURL.path)...")
    try tagger.write(to: outputURL, metadata: metadata)
    print("   Model saved successfully!")
    
    print("\n4. Running validation tests on real notification texts:")
    let compiledURL = try MLModel.compileModel(at: outputURL)
    let model = try MLModel(contentsOf: compiledURL)
    
    let testTexts = [
        "Fineco - SMS Gratuito: Autorizzato utilizzo Carta ***1111 Importo: 6,99 EUR, per: PAYPAL *2CO.COM. Info:",
        "Hai inviato 20,00 € EUR a Lorenzo Riva",
        "Spesi 20,00 € presso PAYPAL *lorenzoriva22",
        "Nexi Informa: autorizzata spesa di EUR 18,20 con carta che termina per 4321 presso MEDIAWORLD MILANO",
        "Intesa Sanpaolo: autorizzato pagamento con carta ***9876 di importo EUR 25,00 presso ENI STATION",
        "Postepay Informa: operazione di 12,00 EUR eseguita il 15/10 con la carta ***2468 presso FARMACIA COMUNALE",
        "Amex: autorizzata spesa di EUR 84,50 con la tua Carta che termina con 1004 presso HOTEL FIRENZE",
        "HYPE: Hai pagato 15,20 € a PIZZERIA DA LUIGI con la tua carta"
    ]
    
    for text in testTexts {
        let input = try MLDictionaryFeatureProvider(dictionary: ["text": text])
        let output = try model.prediction(from: input)
        if let tokens = output.featureValue(for: "tokens")?.sequenceValue?.stringValues,
           let labels = output.featureValue(for: "labels")?.sequenceValue?.stringValues {
            
            var amountVal: Double?
            var merchantWords: [String] = []
            var providerWords: [String] = []
            
            for (t, l) in zip(tokens, labels) {
                switch l.uppercased() {
                case "AMOUNT":
                    let cleaned = t.replacingOccurrences(of: ",", with: ".")
                    amountVal = Double(cleaned)
                case "MERCHANT":
                    merchantWords.append(t)
                case "PROVIDER":
                    providerWords.append(t)
                default:
                    break
                }
            }
            
            print("--------------------------------------------------")
            print("MSG: \(text)")
            print("  -> Importo:   \(amountVal != nil ? "\(amountVal!) €" : "N/D")")
            print("  -> Esercente: \(merchantWords.joined(separator: " "))")
            print("  -> Banca:     \(providerWords.joined(separator: " "))")
        }
    }
} catch {
    print("Error during training:", error)
}
