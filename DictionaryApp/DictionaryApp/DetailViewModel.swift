//
//  DetailViewModel.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import Foundation
import DictionaryAPI

class DetailViewModel {
    var word: Word?
    var networkService: NetworkServiceProtocol
    var originalMeanings: [Meaning]?
    var selectedWordType: String? {
        didSet {
            if let selectedWordType = selectedWordType {
                filteredMeanings = originalMeanings?.filter { $0.partOfSpeech == selectedWordType }
            } else {
                filteredMeanings = originalMeanings
            }
        }
    }
    var filteredMeanings: [Meaning]?

    var wordTypes: [String] {
        get {
            return Array(Set(word?.meanings?.compactMap { $0.partOfSpeech } ?? []))
        }
    }

    var wordText: String? {
        return word?.word
    }

    var phoneticText: String? {
        return word?.phonetic
    }

    init(word: Word, networkService: NetworkServiceProtocol) {
        self.word = word
        self.networkService = networkService
        self.originalMeanings = word.meanings
        self.filteredMeanings = originalMeanings
    }

    func numberOfSections() -> Int {
        return filteredMeanings?.count ?? 0
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        return 1
    }

    func meaningForIndexPath(_ indexPath: IndexPath) -> Meaning? {
        guard let filteredMeanings = filteredMeanings else {
            print("filteredMeanings is nil")
            return nil
        }
        return filteredMeanings[indexPath.section]
    }

    func fetchWordDetails(completion: @escaping (Result<Word, Error>) -> Void) {
        guard let word = word else { return }
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(String(describing: word.word))"
        guard let url = URL(string: urlString) else { return }

        networkService.get(url: url) { data, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                do {
                    let wordDetails = try JSONDecoder().decode([Word].self, from: data)
                    self.word = wordDetails.first
                    self.originalMeanings = self.word?.meanings
                    self.filteredMeanings = self.originalMeanings
                    if let wordDetail = self.word {
                        completion(.success(wordDetail))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Word details not found"])))
                    }
                } catch let error {
                    print("Decoding error: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
}
