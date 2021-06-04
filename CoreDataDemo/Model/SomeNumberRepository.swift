//
//  SomeNumberService.swift
//  CoreDataDemo
//
//  Created by Omar Eduardo Gomez Padilla on 1/06/21.
//

import Foundation
import CoreData

protocol SomeNumberRepository: class {
    
    // synch methods (viewContext)
    func count() throws -> Int
    func someNumber(withId: NSManagedObjectID) throws -> SomeNumber?
    
    // asynch methods (background context)
    func insert(amount: Int32, _ callback: @escaping (Result<NSManagedObjectID, Error>) -> ())
    func batchInsert(amounts: [Int32], _ callback: @escaping (Result<[NSManagedObjectID], Error>) -> ())
    func maxAmount(_ callback: @escaping (Result<Int32, Error>) -> ())
    func deleteAll(_ callback: @escaping (Result<Void, Error>) -> ())
}

class SomeNumberRepositoryImpl: SomeNumberRepository {
    
    static let unexpectedError = NSError(domain: "", code: 401, userInfo: [ NSLocalizedDescriptionKey: "Unexpected Error"])
    
    let entityName = "SomeNumber"
    let viewContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext

    init(viewContext: NSManagedObjectContext = DataStack.shared.viewContext, backgroundContext: NSManagedObjectContext = DataStack.shared.backgroundContext) {
        self.viewContext = viewContext
        self.backgroundContext = backgroundContext
    }
    
    func insert(amount: Int32, _ callback: @escaping (Result<NSManagedObjectID, Error>) -> ()) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            guard let newNumber = NSEntityDescription.insertNewObject(forEntityName: self.entityName, into: self.backgroundContext) as? SomeNumber else {
                callback(.failure(SomeNumberRepositoryImpl.unexpectedError))
                return
            }

            newNumber.amount = amount
            
            do {
                try self.backgroundContext.save()
                callback(.success(newNumber.objectID))
            } catch {
                callback(.failure(error))
            }
        }
    }
    
    func count() throws -> Int {
        return try viewContext.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: entityName))
    }
    
    func maxAmount(_ callback: @escaping (Result<Int32, Error>) -> ()) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            //1.
            let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
            request.entity = NSEntityDescription.entity(forEntityName: self.entityName, in: self.backgroundContext)
            request.resultType = NSFetchRequestResultType.dictionaryResultType

            //2.
            let keypathExpression = NSExpression(forKeyPath: "amount")
            let maxExpression = NSExpression(forFunction: "max:", arguments: [keypathExpression])

            let key = "maxValue"

            //3.
            let expressionDescription = NSExpressionDescription()
            expressionDescription.name = key
            expressionDescription.expression = maxExpression
            expressionDescription.expressionResultType = .integer32AttributeType

            //4.
            request.propertiesToFetch = [expressionDescription]

            do {
                //5.
                if let result = try self.backgroundContext.fetch(request) as? [[String: Int32]], let dict = result.first,
                   let maxResult = dict[key]{
                    callback(.success(maxResult))
                } else {
                    callback(.failure(SomeNumberRepositoryImpl.unexpectedError))
                }
                
            } catch {
                callback(.failure(error))
            }
            
        }
    }

    func deleteAll(_ callback: @escaping (Result<Void, Error>) -> ()) {
        backgroundContext.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SomeNumber")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try self.backgroundContext.execute(deleteRequest)
                callback(.success(Void()))
            } catch let error as NSError {
                callback(.failure(error))
            }
        }
    }
    
    func someNumber(withId: NSManagedObjectID) throws -> SomeNumber? {
        let obj = try self.viewContext.existingObject(with: withId)
        return obj as? SomeNumber
    }

    func batchInsert(amounts: [Int32], _ callback: @escaping (Result<[NSManagedObjectID], Error>) -> ()) {
        backgroundContext.perform {
            let insertRequest = NSBatchInsertRequest(entityName: self.entityName, objects: amounts.map {["amount": $0]})
            insertRequest.resultType = NSBatchInsertRequestResultType.objectIDs
            
            do {
                let result = try self.backgroundContext.execute(insertRequest) as? NSBatchInsertResult

                if let objectIDs = result?.result as? [NSManagedObjectID], !objectIDs.isEmpty {
                    callback(.success(objectIDs))
                } else {
                    callback(.failure(SomeNumberRepositoryImpl.unexpectedError))
                }
            } catch {
                callback(.failure(error))
            }
            
        }
    }

}
