//
//  WordViewModel.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import Foundation

import DictionaryAPI

class WordViewModel {
    let networkService: NetworkServiceProtocol
    var word: Word?
    
    public init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func fetchWord(_ word: String, completion: @escaping (Result<[Word], Error>) -> Void) {
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(word)") else {
            completion(.failure(NSError(domain: "NetworkServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey : "Invalid URL"])))
            return
        }
        
        networkService.get(url: url) { [weak self] data, error in
                if let error = error {
                    completion(.failure(error))
                } else if let data = data {
                    print(String(data: data, encoding: .utf8) ?? "Could not decode data")
                    let decoder = JSONDecoder()
                    if let wordData = try? decoder.decode([Word].self, from: data) {
                        self?.word = wordData.first
                        completion(.success(wordData))
                    } else {
                        completion(.failure(NSError(domain: "NetworkServiceError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode response"])))
                    }
                } else {
                    completion(.failure(NSError(domain: "NetworkServiceError", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
            }
        }
    }

