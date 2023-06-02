import Foundation
import DictionaryAPI
import AVFoundation

protocol DetailViewModelDelegate: AnyObject {
    func updateUI()
    func reloadSynonymsCollectionView()
    func reloadFilteredCollectionView()
    func reloadWordMeaningTableView()
    func audioButtonIsVisibilty()
}

protocol DetailViewModelProtocol {
    var delegate: DetailViewModelDelegate? { get set }
    func getPhonetics() -> [Phonetic]?
    var onSelectedWordTypesUpdated: (() -> Void)? { get set }
    var onWordTypesUpdated: (() -> Void)? { get set }
    func fetchWordDetails(completion: @escaping (Result<Word, Error>) -> Void)
    func fetchFilteredSynonyms(word: String, completion: @escaping (Result<[Synonym], Error>) -> Void)
    func isAudioURLValid(completion: @escaping (Bool) -> Void)
    func playAudio(completion: @escaping (Error?) -> Void)
    var wordText: String? { get }
    var phoneticText: String? { get }
    var numberOfWordTypes: Int { get }
    func getWordTypes(_ index: Int) -> String?
    func getCountGroupedDefinitions(_ wordType: String) -> Int
    func definitionForIndexPath(_ indexPath: IndexPath) -> Definition?
    func meaningIndexForType(_ type: String, indexPath: IndexPath) -> Int
    var numberOfFilteredSynonyms: Int { get }
    var isFiltering: Bool { get set }
    var selectedWordType: String? { get set }
    func getCountFilteredSynonyms(_ index: Int) -> Synonym?
    var selectedWordTypes: [String] { get set }
        
}

final class DetailViewModel {
    //MARK: - Definations Variables
    weak var delegate: DetailViewModelDelegate?
    var player: AVPlayer?
    var word: Word?
    var networkService: NetworkServiceProtocol
    var originalMeanings: [Meaning]?
    var filteredSynonyms: [Synonym] = []
    var wordTypes: [String] = []
    var filteredMeanings: [Meaning]?
    var groupedDefinitions: [String: [Definition]] = [:]
    
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
    init(word: Word) {
        self.word = word
        self.networkService = NetworkService()
        self.originalMeanings = word.meanings?.sorted(by: { $0.partOfSpeech ?? "" < $1.partOfSpeech ?? "" })
        
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
    // MARK: - TableView Functions
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
    
    //MARK: - Audio Button Operations
    func playAudio(completion: @escaping (Error?) -> Void) {
        guard let phonetics = getPhonetics() else {
            
            return
        }
        
        for phonetic in phonetics {
            if let urlString = phonetic.audio,
               let url = URL(string: urlString) {
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 1.0
                
                let task = URLSession.shared.dataTask(with: request) { [weak self] (_, response, error) in
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        DispatchQueue.main.async {
                            self?.player = AVPlayer(url: url)
                            self?.player?.play()
                        }
                        completion(nil)
                        return
                    }
                    completion(error)
                }
                task.resume()
            }
        }
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

// MARK: - DetailViewModel Protocol Functions
extension DetailViewModel: DetailViewModelProtocol {
    func getCountFilteredSynonyms(_ index: Int) -> Synonym? {
        if index >= 0 && index < numberOfFilteredSynonyms {
            return filteredSynonyms[index]
        }
        return nil
    }
    
    var numberOfFilteredSynonyms: Int {
        filteredSynonyms.count
    }
    
    func getCountGroupedDefinitions(_ wordType: String) -> Int {
        return groupedDefinitions[wordType]?.count ?? 0
    }
    
    func getWordTypes(_ index: Int) -> String? {
        if index >= 0 && index < numberOfWordTypes {
            return wordTypes[index]
        }
        return nil
    }
    
    var numberOfWordTypes: Int {
        wordTypes.count
    }
    
    func getPhonetics() -> [Phonetic]? {
        return word?.phonetics
    }
}
