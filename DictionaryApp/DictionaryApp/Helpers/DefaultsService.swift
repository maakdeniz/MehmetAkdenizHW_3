//
//  DefaultsService.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import Foundation
import DictionaryAPI

struct DefaultsService {
    private let defaults = UserDefaults.standard
    
    func getSearchHistory() -> [Word]? {
        if let data = defaults.object(forKey: "searchHistory") as? Data {
            let decoder = JSONDecoder()
            return try? decoder.decode([Word].self, from: data)
        }
        return nil
    }
    
    func saveSearchHistory(_ searchHistory: [Word]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(searchHistory) {
            defaults.set(encoded, forKey: "searchHistory")
        }
    }
}

