import Foundation

enum Language: String, CaseIterable, Codable {
    case ru = "ru"
    case en = "en"
    case zhHans = "zh-Hans"

    var displayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        case .zhHans: return "简体中文"
        }
    }

    var nativeDisplayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        case .zhHans: return "简体中文"
        }
    }

    var locale: Locale {
        Locale(identifier: self == .ru ? "ru_RU" : (self == .zhHans ? "zh_CN" : "en_US"))
    }

    static var current: Language {
        let saved = UserDefaults.standard.string(forKey: "app.language")
        return Language(rawValue: saved ?? "") ?? .ru
    }
}
