//
//  NetworkService.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import Foundation

public protocol NetworkServiceProtocol {
    func get(url: URL, completion: @escaping (Data?,Error?) -> Void)
}

open class NetworkService: NetworkServiceProtocol {
    
    public init () { }
    
    public func get(url: URL, completion: @escaping (Data?,Error?) -> Void) {
         let task = URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data,error)
        }
        task.resume()
    }
}
