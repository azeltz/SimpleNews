//
//  SavedArticlesStorage.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import Foundation

private let savedIDsKey = "savedArticleIDs"

struct SavedArticlesStorage {
    static func load() -> Set<String> {
        let ids = UserDefaults.standard.stringArray(forKey: savedIDsKey) ?? []
        return Set(ids)
    }

    static func save(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: savedIDsKey)
    }
}
