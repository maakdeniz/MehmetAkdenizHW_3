//
//  WordModel.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import Foundation

public struct Word: Codable {
    public let word: String
    public let phonetic: String?
    public let phonetics: [Phonetic]?
    public var meanings: [Meaning]?
    public let license: License?
    public let sourceUrls: [String]?
}

public struct Phonetic: Codable {
    public let text: String?
    public let audio: String?
}

public struct Meaning: Codable {
    public let partOfSpeech: String?
    public let definitions: [Definition]
    public let synonyms: [String]?
    public let antonyms: [String]?
}

public struct Definition: Codable {
    public let definition: String
    public let example: String?
    public let synonyms: [String]?
    public let antonyms: [String]?
}

public struct License: Codable {
    public let name: String
    public let url: String
}

public struct Synonym: Codable {
    public let word: String?
    public let score: Int?
}
