import Foundation
import NaturalLanguage

struct TaggedSentence {
    let text: String
    let provider: String?
    let amount: String
    let merchant: String
}

struct TrainingEntry: Codable {
    let tokens: [String]
    let labels: [String]
}

// MARK: - Dataset Components

let merchants = [
    // Supermarkets & Retail
    "ESSELUNGA",
    "Esselunga Superstore",
    "CONAD",
    "Conad City",
    "COOP",
    "Ipercoop",
    "CARREFOUR",
    "Carrefour Express",
    "LIDL",
    "Eurospin",
    "Pam Panorama",
    "Tigros",
    "Decathlon",
    "MediaWorld",
    "Unieuro",
    "IKEA",
    "Leroy Merlin",
    "Zara",
    "H&M",
    
    // E-commerce & Subscriptions
    "AMAZON EU",
    "Amazon Prime",
    "PAYPAL *NETFLIX",
    "PAYPAL *SPOTIFY",
    "PAYPAL *STEAM",
    "PAYPAL *2CO.COM",
    "PAYPAL *lorenzoriva22",
    "PAYPAL *EBAY",
    "Apple.com/bill",
    "Zalando",
    "Shein",
    "Deliveroo",
    "Just Eat",
    "Glovo",
    "Uber",
    
    // Bars, Food & Bakeries
    "Bar Centrale",
    "Bar San Marco",
    "Pasticceria Roma",
    "Pizzeria Da Luigi",
    "Ristorante Il Ponte",
    "Trattoria Del Sole",
    "Starbucks Coffee",
    "McDonald's",
    "Burger King",
    "Poke House",
    "Le Golosie",
    
    // Health & Pharmacies
    "Farmacia San Carlo",
    "Farmacia Comunale",
    "Farmacia Centrale",
    "Parafarmacia Conad",
    
    // Transport & Fuel
    "Eni Station",
    "Q8 Easy",
    "IP Gruppo api",
    "Esso",
    "Telepass",
    "Trenitalia",
    "Italo Treno",
    "Ryanair",
    
    // P2P Contacts (for transfers)
    "Lorenzo Riva",
    "Marco Rossi",
    "Giulia Bianchi",
    "Matteo Ferrari",
    "Sara Colombo",
    "Davide Esposito",
    "Francesca Ricci",
    "Andrea Romano"
]

let amounts = [
    "1,50", "2,20", "3,50", "4,00", "5,50", "6,99", "8,50", "9,80",
    "10,00", "12,50", "14,50", "15,00", "18,20", "19,90", "20,00",
    "22,40", "25,00", "28,50", "32,80", "34,90", "42,00", "45,50",
    "50,00", "58,00", "60,00", "75,50", "84,00", "99,00", "99,99",
    "120,00", "145,50", "180,00", "250,00", "310,00", "500,00",
    // Dot notations
    "6.99", "12.50", "14.50", "20.00", "34.90", "50.00", "99.00"
]

let cardDigits = ["1111", "1234", "4321", "5678", "9876", "2468", "3321", "8899", "7654"]
let dates = ["15/10", "18/10", "19/10", "20/10", "12/11", "03/12", "ieri", "oggi"]
let times = ["08:30", "12:15", "14:32", "16:30", "18:45", "20:10", "21:15"]

// MARK: - Template Builders

typealias TemplateBuilder = (String, String, String, String, String, String) -> TaggedSentence

struct BankTemplateGroup {
    let provider: String?
    let templates: [TemplateBuilder]
}

let bankTemplateGroups: [BankTemplateGroup] = [
    // 1. Fineco
    BankTemplateGroup(
        provider: "Fineco",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Fineco - SMS Gratuito: Autorizzato utilizzo Carta ***\(c) Importo: \(a) EUR, per: \(m). Info: 0228992899",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Fineco: autorizzato pagamento con Carta ***\(c) di EUR \(a) presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Fineco: autorizzata operazione di EUR \(a) con Carta ***\(c) per: \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 2. Nexi
    BankTemplateGroup(
        provider: "Nexi",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Nexi Informa: autorizzata spesa di EUR \(a) con carta che termina per \(c) presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Spesa autorizzata di EUR \(a) effettuata con carta ***\(c) c/o \(m)",
                    provider: nil, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Nexi: autorizzato pagamento di \(a) EUR presso \(m) il \(d)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 3. Intesa Sanpaolo / Isybank
    BankTemplateGroup(
        provider: "Intesa Sanpaolo",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Intesa Sanpaolo: autorizzato pagamento con carta ***\(c) di importo EUR \(a) presso \(m) il \(d) alle \(t)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Intesa Sanpaolo: autorizzata operazione di EUR \(a) presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Isybank: Hai effettuato un pagamento di \(a) € presso \(m) con la tua carta",
                    provider: "Isybank", amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 4. UniCredit
    BankTemplateGroup(
        provider: "UniCredit",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "UniCredit Informa: autorizzata operazione di EUR \(a) con carta ***\(c) a favore di \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "UniCredit: Pagamento autorizzato di \(a) € presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "UniCredit Informa: spesa di EUR \(a) con carta *\(c) presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 5. PostePay / BancoPosta
    BankTemplateGroup(
        provider: "Postepay",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Postepay Informa: operazione di \(a) EUR eseguita il \(d) con la carta ***\(c) presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Postepay: pagamento di \(a) € autorizzato presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 6. BBVA
    BankTemplateGroup(
        provider: "BBVA",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Acquisto autorizzato con la tua carta BBVA per \(a) € presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "BBVA: Hai effettuato un acquisto di \(a) EUR presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "BBVA: Hai inviato \(a) € a \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 7. HYPE
    BankTemplateGroup(
        provider: "HYPE",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "HYPE: Hai pagato \(a) € a \(m) con la tua carta",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "HYPE: Spesa di \(a) € effettuata presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "\(m) \(a) €",
                    provider: nil, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 8. Revolut
    BankTemplateGroup(
        provider: "Revolut",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Hai speso \(a) € da \(m) con la tua carta virtuale",
                    provider: nil, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Hai speso \(a) € da \(m)",
                    provider: nil, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Hai inviato \(a) € a \(m)",
                    provider: nil, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Revolut: \(a) EUR spesi presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 9. PayPal (Push app & Generic)
    BankTemplateGroup(
        provider: "PayPal",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Hai inviato \(a) € EUR a \(m)",
                    provider: nil, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Hai inviato \(a) EUR a \(m)",
                    provider: nil, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Hai pagato \(a) EUR a \(m)",
                    provider: nil, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Spesi \(a) € presso \(m)",
                    provider: nil, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "PayPal: pagamento di \(a) EUR a \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 10. American Express (Amex)
    BankTemplateGroup(
        provider: "Amex",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Amex: autorizzata spesa di EUR \(a) con la tua Carta che termina con \(c) presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "American Express Informa: autorizzato pagamento di EUR \(a) c/o \(m)",
                    provider: "American Express", amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 11. Banca Sella
    BankTemplateGroup(
        provider: "Banca Sella",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Banca Sella: autorizzato pagamento di EUR \(a) con carta *\(c) presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 12. Banco BPM
    BankTemplateGroup(
        provider: "Banco BPM",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Banco BPM Informa: autorizzato pagamento con carta ***\(c) di EUR \(a) presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 13. Banca Mediolanum
    BankTemplateGroup(
        provider: "Banca Mediolanum",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Banca Mediolanum: operazione di \(a) EUR autorizzata con carta *\(c) presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 14. ING
    BankTemplateGroup(
        provider: "ING",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Alert Arancio: effettuato pagamento con carta di EUR \(a) presso \(m)",
                    provider: "ING", amount: a, merchant: m
                )
            }
        ]
    ),
    
    // 15. N26
    BankTemplateGroup(
        provider: "N26",
        templates: [
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "Hai speso \(a) € da \(m) con la tua Mastercard N26",
                    provider: p, amount: a, merchant: m
                )
            },
            { p, m, a, c, d, t in
                TaggedSentence(
                    text: "N26: Pagamento di \(a) EUR presso \(m)",
                    provider: p, amount: a, merchant: m
                )
            }
        ]
    )
]

// MARK: - Exact Tokenization & Tagging matching Apple NaturalLanguage Runtime

func tokenizeAndTag(sample: TaggedSentence) -> TrainingEntry? {
    let tagger = NLTagger(tagSchemes: [.tokenType])
    tagger.string = sample.text
    
    var tokens: [String] = []
    var labels: [String] = []
    
    guard let amountRange = sample.text.range(of: sample.amount),
          let merchantRange = sample.text.range(of: sample.merchant) else {
        return nil
    }
    
    let providerRange = sample.provider.flatMap { sample.text.range(of: $0) }
    
    tagger.enumerateTags(in: sample.text.startIndex..<sample.text.endIndex, unit: .word, scheme: .tokenType) { tag, range in
        guard tag != .whitespace else { return true }
        
        let token = String(sample.text[range])
        tokens.append(token)
        
        if range.lowerBound >= amountRange.lowerBound && range.upperBound <= amountRange.upperBound {
            labels.append("AMOUNT")
        } else if range.lowerBound >= merchantRange.lowerBound && range.upperBound <= merchantRange.upperBound {
            labels.append("MERCHANT")
        } else if let pr = providerRange, range.lowerBound >= pr.lowerBound && range.upperBound <= pr.upperBound {
            labels.append("PROVIDER")
        } else {
            labels.append("NONE")
        }
        return true
    }
    
    // Sanity check: must contain at least 1 AMOUNT and 1 MERCHANT token
    guard labels.contains("AMOUNT") && labels.contains("MERCHANT") && tokens.count == labels.count else {
        return nil
    }
    
    return TrainingEntry(tokens: tokens, labels: labels)
}

// MARK: - Generation Execution

var dataset: [TrainingEntry] = []

for group in bankTemplateGroups {
    for template in group.templates {
        // Generate 10 variations for each template
        for _ in 0..<10 {
            let m = merchants.randomElement()!
            let a = amounts.randomElement()!
            let c = cardDigits.randomElement()!
            let d = dates.randomElement()!
            let t = times.randomElement()!
            
            let sample = template(group.provider ?? "", m, a, c, d, t)
            if let entry = tokenizeAndTag(sample: sample) {
                dataset.append(entry)
            }
        }
    }
}

// Shuffle dataset
dataset.shuffle()

print("Generated \(dataset.count) valid training examples.")

// Encode to JSON
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted]
let jsonData = try encoder.encode(dataset)

let outputPath = "/Users/riccardomodina/src/PileUp/pileup-ios/MLData/data/bank_notifications_training.json"
try jsonData.write(to: URL(fileURLWithPath: outputPath))

print("Saved dataset to \(outputPath)")
