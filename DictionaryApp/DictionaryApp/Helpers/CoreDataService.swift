//
//  CoreDataService.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 30.05.2023.
// CoreDataService.swift

import Foundation
import CoreData
import UIKit
import DictionaryAPI

struct CoreDataService {

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let context: NSManagedObjectContext
    
    init() {
        context = appDelegate.persistentContainer.viewContext
    }
    
    func getSearchHistory() -> [String]? {
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.fetchLimit = 5
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        do {
            let result = try context.fetch(request)
            return result.compactMap { $0.word }
        } catch {
            
            return nil
        }
    }

    
    func saveSearchHistory(_ word: String) {
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            let results = try context.fetch(request)
            if let wordEntity = results.first {
                
                wordEntity.date = Date()
            } else {
                
                let newWordEntity = WordEntity(context: context)
                newWordEntity.word = word
                newWordEntity.date = Date()
            }
            try context.save()
        } catch {
            
        }
    }

    
    func deleteOldWords() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "WordEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 5 {
                context.delete(results.first as! NSManagedObject)
            }
        } catch {
            
        }
    }
}



