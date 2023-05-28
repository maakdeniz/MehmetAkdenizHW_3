import Foundation
import DictionaryAPI

class DetailViewModel {
    var word: Word?
    var networkService: NetworkServiceProtocol
    var originalMeanings: [Meaning]?
    var filteredSynonyms: [Synonym] = []
    
    var isFiltering: Bool = false {
            didSet {
                if isFiltering {
                    if !wordTypes.contains("X") {
                        wordTypes.insert("X", at: 0)
                    }
                } else {
                    if let index = wordTypes.firstIndex(of: "X") {
                        wordTypes.remove(at: index)
                    }
                }
                onWordTypesUpdated?()
            }
        }
    
    var selectedWordType: String? {
            didSet {
                if let selectedWordType = selectedWordType {
                    isFiltering = true
                    filteredMeanings = originalMeanings?.filter { $0.partOfSpeech == selectedWordType }
                } else {
                    isFiltering = false
                    filteredMeanings = originalMeanings
                }
                word?.meanings = filteredMeanings
            }
        }
    
    var selectedWordTypes: [String] = [] {
        didSet {
            if !selectedWordTypes.isEmpty {
                isFiltering = true
                filteredMeanings = originalMeanings?.filter { selectedWordTypes.contains($0.partOfSpeech ?? "") }
            } else {
                isFiltering = false
                filteredMeanings = originalMeanings
            }
            word?.meanings = filteredMeanings
        }
    }
    var filteredMeanings: [Meaning]?
    var onWordTypesUpdated: (() -> Void)?

    var wordTypes: [String] = []

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
                    DispatchQueue.main.async {
                        self.wordTypes = Array(Set(self.word?.meanings?.compactMap { $0.partOfSpeech } ?? []))
                        self.onWordTypesUpdated?()
                    }
                    if let wordDetail = self.word {
                        completion(.success(wordDetail))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Word details not found"])))
                    }
                } catch let error {
                    print("Failed to decode: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    
    func fetchFilteredSynonyms(word: String, completion: @escaping (Result<[Synonym], Error>) -> Void) {
        guard let url = URL(string: "https://api.datamuse.com/words?rel_syn=\(word)") else {
            completion(.failure(NSError(domain: "NetworkServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey : "Invalid URL"])))
            return
        }
        
        networkService.get(url: url) { data, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                let decoder = JSONDecoder()
                if let synonymData = try? decoder.decode([Synonym].self, from: data) {
                    self.filteredSynonyms = synonymData.sorted { ($0.score ?? 0) > ($1.score ?? 0) }.prefix(5).map { $0 }
                    completion(.success(synonymData))
                } else {
                    completion(.failure(NSError(domain: "NetworkServiceError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode response"])))
                }
            } else {
                completion(.failure(NSError(domain: "NetworkServiceError", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            }
        }
    }
}
    
    

