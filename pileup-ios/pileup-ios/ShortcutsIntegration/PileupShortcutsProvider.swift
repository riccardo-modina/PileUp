import AppIntents

/// Automatically registers and exposes PileUp shortcuts in iOS Shortcuts upon app installation.



@available(iOS 16.0, *)
public struct PileupShortcutsProvider: AppShortcutsProvider {

    public static var appShortcuts: [AppShortcut] {

        /// LogWalletTransaction
        ///
        /// Allows the user to capture and record an expense movement intercepted from any source:
        /// Apple Wallet (Apple Pay), bank push notifications, banking SMS alerts, or custom personal automations.
        ///
        /// Important: This shortcut does not trigger itself automatically. It requires an iOS Personal Automation
        /// (e.g., triggered on "Card Transaction" in Wallet or "When I Receive a Message" for banking alerts)
        /// configured by the user to invoke it and pass the transaction data; otherwise, it will do nothing on its own.
        AppShortcut(
            intent: LogWalletTransactionIntent(),
            phrases: [
                "Registra movimento di spesa in \(.applicationName)",
                "Registra spesa con \(.applicationName)",
                "Aggiungi movimento di spesa in \(.applicationName)",
                "Salva spesa intercettata in \(.applicationName)",
                "Intercetta movimento in \(.applicationName)"
            ],
            shortTitle: "Registra Movimento di Spesa",
            systemImageName: "cart.badge.plus"
        )
    }
}