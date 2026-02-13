//
//  Settings.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import Foundation

enum NewsLanguage: String, CaseIterable, Identifiable, Codable {
    case en   // English
    case es   // Spanish
    case fr   // French
    case de   // German
    case it   // Italian
    case he   // Hebrew

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .es: return "Spanish"
        case .fr: return "French"
        case .de: return "German"
        case .it: return "Italian"
        case .he: return "Hebrew"
        }
    }
}

let knownCategories: Set<String> = [
    "top",
    "business",
    "entertainment",
    "environment",
    "food",
    "health",
    "politics",
    "science",
    "sports",
    "technology",
    "world"
]


struct AppSettings: Codable {
    var language: NewsLanguage = .en
    var showImages: Bool = true
}
