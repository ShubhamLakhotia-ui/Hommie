import Foundation
import SwiftUI
import Combine

// Manages app language — persists selection using UserDefaults
class LocalizationManager: ObservableObject {
    
    static let shared = LocalizationManager()
    
    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        case hindi = "hi"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .hindi: return "हिंदी"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .spanish: return "🇪🇸"
            case .hindi: return "🇮🇳"
            }
        }
    }
    
    // Saved to UserDefaults so language persists across app launches
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            Bundle.setLanguage(currentLanguage.rawValue)
        }
    }
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let language = Language(rawValue: saved) {
            currentLanguage = language
            Bundle.setLanguage(saved)
        } else {
            currentLanguage = .english
        }
    }
    
    func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}

// Global variable outside any type — fixes static member error
private var bundleAssociationKey: UInt8 = 0

extension Bundle {
    
    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, AnyLanguageBundle.self)
        }
        objc_setAssociatedObject(
            Bundle.main,
            &bundleAssociationKey,
            Bundle(path: Bundle.main.path(forResource: language, ofType: "lproj") ?? ""),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
    
    class AnyLanguageBundle: Bundle {
        override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
            guard let bundle = objc_getAssociatedObject(self, &bundleAssociationKey) as? Bundle else {
                return super.localizedString(forKey: key, value: value, table: tableName)
            }
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
    }
}

// Use .localized on any String key to get translated text
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
