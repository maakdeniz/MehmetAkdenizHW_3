//
//  CoreDataService.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 30.05.2023.
//

import CoreData
import UIKit
import DictionaryAPI




class CoreDataService {
    // Referans to managedObjectContext
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // Fetch Words from CoreData
    func fetchWords() -> [WordEntity]? {
        do {
            let request = WordEntity.fetchRequest() as NSFetchRequest<WordEntity>
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            let words = try context.fetch(request)
            return words
        } catch {
            print("Failed to fetch words from CoreData")
            return nil
        }
    }
    
    // Save Word to CoreData
    func saveWord(_ word: String) {
        let entity = WordEntity(context: context)
        entity.word = word
        entity.date = Date()
        do {
            try context.save()
        } catch {
            print("Failed to save word to CoreData")
        }
    }
    
    // Delete the oldest word if there are more than 5 words
    func deleteOldestWordIfNeeded() {
        if let words = fetchWords(), words.count > 5 {
            context.delete(words.last!)
            do {
                try context.save()
            } catch {
                print("Failed to delete word from CoreData")
            }
        }
    }
}



