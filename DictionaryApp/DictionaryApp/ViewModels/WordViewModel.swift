import Foundation
import DictionaryAPI

protocol WordViewModelDelegate: AnyObject {
    func didUpdateWord(_ viewModel: WordViewModel)
    func didFailWithError(_ viewModel: WordViewModel, error: Error)
    func navigateToDetailViewController()
    func reloadData()
}

protocol WordViewModelProtocol {
    
    var delegate: WordViewModelDelegate? { get set }
    var searchHistory: [String] { get }
    func getWord() -> Word?
    func fetchWord(_ word: String)
    func searchWord(word: String)
    func navigateToDetail()
}


final class WordViewModel: WordViewModelProtocol {
    func getWord() -> Word? {
        return word
    }

    let networkService: NetworkServiceProtocol
    private var coreDataService: CoreDataService
    var word: Word?
    weak var delegate: WordViewModelDelegate?
    var searchHistory: [String] = []
    
    init(coreDataService: CoreDataService) {
        self.networkService = NetworkService()
        self.coreDataService = coreDataService
        self.searchHistory = coreDataService.getSearchHistory() ?? []
    }
    
    enum FetchWordError: Error {
        case wordNotFound
    }
    //MARK: - Network Function
    func fetchWord(_ word: String) {
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(word)") else {
            delegate?.didFailWithError(self, error: NSError(domain: "NetworkServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey : "Invalid URL"]))
            return
        }
        
        networkService.get(url: url) { [weak self] data, error in
            self?.handleNetworkResult(data: data, error: error)
        }
    }
    
    func handleNetworkResult(data: Data?, error: Error?) {
        if let error = error {
            self.delegate?.didFailWithError(self, error: error)
        } else if let data = data {
            let decoder = JSONDecoder()
            if let wordData = try? decoder.decode([Word].self, from: data) {
                if wordData.isEmpty {
                    self.delegate?.didFailWithError(self, error: FetchWordError.wordNotFound)
                } else {
                    guard let word = wordData.first else {
                        return
                    }
                    self.word = word
                    self.coreDataService.saveSearchHistory(word.word)
                    self.coreDataService.deleteOldWords()
                    self.searchHistory = self.coreDataService.getSearchHistory() ?? []
                    self.delegate?.didUpdateWord(self)
                }
            } else {
                self.delegate?.didFailWithError(self, error: NSError(domain: "NetworkServiceError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode response"]))
            }
        } else {
            self.delegate?.didFailWithError(self, error: NSError(domain: "NetworkServiceError", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
        }
    }
    
    func searchWord(word: String) {
            fetchWord(word)
        }
    func navigateToDetail() {
           delegate?.navigateToDetailViewController()
       }
    
}
