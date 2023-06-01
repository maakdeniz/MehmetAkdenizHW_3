import Foundation
import DictionaryAPI

class DetailViewModel {
    //MARK: - Definations Variables
    var word: Word?
    var networkService: NetworkServiceProtocol
    var originalMeanings: [Meaning]?
    var filteredSynonyms: [Synonym] = []
    var meaningCounts: [String: Int] = [:]
    var wordTypes: [String] = []
    var filteredMeanings: [Meaning]?
    var groupedDefinitions: [String: [Definition]] = [:]
    var meaningIndices: [String: Int] = [:]
    
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
                onSelectedWordTypesUpdated?()
            }
        }
    var selectedWordType: String? {
        didSet {
            if let selectedWordType = selectedWordType {
                isFiltering = true
                filteredMeanings = originalMeanings?.filter { $0.partOfSpeech == selectedWordType }
                word?.meanings = filteredMeanings
            } else {
                isFiltering = false
                filteredMeanings = originalMeanings
                word?.meanings = filteredMeanings
            }
            onSelectedWordTypesUpdated?()
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

            if let meanings = word?.meanings {
                var newGroupedDefinitions: [String: [Definition]] = [:]

                for meaning in meanings {
                    if let pos = meaning.partOfSpeech {
                        if newGroupedDefinitions[pos] != nil {
                            newGroupedDefinitions[pos]?.append(contentsOf: meaning.definitions )
                        } else {
                            newGroupedDefinitions[pos] = meaning.definitions
                        }
                    }
                }

                self.groupedDefinitions = newGroupedDefinitions
            }
            onSelectedWordTypesUpdated?()
        }
    }
    var wordText: String? {
        return word?.word
    }
    var phoneticText: String? {
        return word?.phonetic
    }
//MARK: - Closures
    var onSelectedWordTypesUpdated: (() -> Void)?
    var onWordTypesUpdated: (() -> Void)?
    
//MARK: - Initiliazer
    init(word: Word, networkService: NetworkServiceProtocol) {
            self.word = word
            self.networkService = networkService
            self.originalMeanings = word.meanings?.sorted(by: { $0.partOfSpeech ?? "" < $1.partOfSpeech ?? "" })
            
            // Her bir Meaning'deki Definition'ları ayırın ve bunları groupedDefinitions'a atayın:
            if let meanings = word.meanings {
                for meaning in meanings {
                    for definition in meaning.definitions {
                        if let pos = meaning.partOfSpeech {
                            if groupedDefinitions[pos] != nil {
                                groupedDefinitions[pos]?.append(definition)
                            } else {
                                groupedDefinitions[pos] = [definition]
                            }
                        }
                    }
                }
            }
        }
    func numberOfSections() -> Int {
            return wordTypes.count
        }
    func numberOfRowsInSection(_ section: Int) -> Int {
            let partOfSpeech = wordTypes[section]
            return groupedDefinitions[partOfSpeech]?.count ?? 0
        }
    func definitionForIndexPath(_ indexPath: IndexPath) -> Definition? {
            let partOfSpeech = wordTypes[indexPath.section]
            let definitions = groupedDefinitions[partOfSpeech]
            let definition = definitions?[indexPath.row]
            return definition
        }
    func meaningIndexForType(_ type: String, indexPath: IndexPath) -> Int {
          return indexPath.row + 1
      }
    func isAudioURLValid(completion: @escaping (Bool) -> Void) {
        guard let phonetics = word?.phonetics else {
            completion(false)
            return
        }

        let dispatchGroup = DispatchGroup()

        var validURLExists = false
        for phonetic in phonetics {
            if let urlString = phonetic.audio, let url = URL(string: urlString) {
                dispatchGroup.enter()
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 1.0

                let task = URLSession.shared.dataTask(with: request) { (_, response, error) in
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        validURLExists = true
                    }
                    dispatchGroup.leave()
                }
                task.resume()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(validURLExists)
        }
    }

    //MARK: - Network Functions
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
