import Foundation
import AppIntents

// 🎤 GİDER EKLEME INTENT
@available(iOS 16.0, *)
struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Gider Ekle"
    static var description = IntentDescription("Sesli komut ile hızlı gider ekle")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// 💰 GELİR EKLEME INTENT
@available(iOS 16.0, *)
struct AddIncomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Gelir Ekle"
    static var description = IntentDescription("Hızlı gelir kaydı yap")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// 📸 FATURA TARAMA INTENT
@available(iOS 16.0, *)
struct ScanReceiptIntent: AppIntent {
    static var title: LocalizedStringResource = "Fatura Tara"
    static var description = IntentDescription("Kamera ile fatura okuma yap")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// 📊 İSTATİSTİKLER INTENT
@available(iOS 16.0, *)
struct ViewStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "İstatistikler"
    static var description = IntentDescription("Finansal istatistiklerini görüntüle")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// 🎯 SİRİ SHORTCUTS SAĞLAYICI
@available(iOS 16.0, *)
struct FinAIShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Gider ekle \(.applicationName)",
                "\(.applicationName) ile gider ekle",
                "\(.applicationName) gider"
            ],
            shortTitle: "Gider Ekle",
            systemImageName: "minus.circle.fill"
        )
        
        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "Gelir ekle \(.applicationName)",
                "\(.applicationName) ile gelir ekle",
                "\(.applicationName) gelir"
            ],
            shortTitle: "Gelir Ekle",
            systemImageName: "plus.circle.fill"
        )
        
        AppShortcut(
            intent: ScanReceiptIntent(),
            phrases: [
                "Fatura tara \(.applicationName)",
                "\(.applicationName) ile fatura tara",
                "\(.applicationName) fatura"
            ],
            shortTitle: "Fatura Tara",
            systemImageName: "camera.fill"
        )
        
        AppShortcut(
            intent: ViewStatsIntent(),
            phrases: [
                "İstatistiklerimi göster \(.applicationName)",
                "\(.applicationName) istatistikler",
                "\(.applicationName) özet"
            ],
            shortTitle: "İstatistikler",
            systemImageName: "chart.bar.fill"
        )
    }
}
