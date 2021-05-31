//
//  MainPresenter.swift
//  CoreDataDemo
//
//  Created by Omar Gomez on 28/05/21.
//

import Foundation
import CoreData

protocol MainView: class {
 
    func update(count: Int)
    func update(recordCount: Int)
    func alert(title: String, message: String)
    func onNewNumber()
    
}

class MainPresenter {
    
    weak var view: MainView!
    var tasks: [DispatchWorkItem]
    var queue = DispatchQueue(label: "tasks-queue", qos: .default, attributes: .concurrent)
    let container: NSPersistentContainer
    var lastId: NSManagedObjectID?

    var currCount: Int? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SomeNumber")
        do {
            return try container.viewContext.count(for: fetchRequest)
        } catch {
            return nil
        }
    }
    
    init(view: MainView, container: NSPersistentContainer) {
        self.view = view
        self.container = container
        tasks = []
    }
    
    func viewDidLoad() {
        self.view.update(recordCount: self.currCount ?? -1 )
        self.view.update(count: 0 )
    }
    
    func addTask() {
        
        var aTask: DispatchWorkItem?
        
        aTask = DispatchWorkItem(block: { [weak self] in
            guard let task = aTask else {
                return
            }
            while self?.taskTick(task: task) ?? false {
                Thread.sleep(forTimeInterval: Double.random(in: 0.5...1.5))
            }
        })
        
        guard let task = aTask else { return }
        
        tasks.append(task)
        self.queue.async(execute: task)

        self.view.update(count: self.tasks.count)
    }
    
    func removeTask() {
        
        if let task = tasks.last {
            task.cancel()
            tasks.removeLast()
            
            self.view.update(count: self.tasks.count)
        }
        
    }
    
    func taskTick(task: DispatchWorkItem) -> Bool {
        guard !task.isCancelled else {
            return false
        }
        
        // logic
        let context = self.container.newBackgroundContext()
        context.performAndWait {
            
            guard let newNumber = NSEntityDescription.insertNewObject(forEntityName: "SomeNumber", into: context) as? SomeNumber else {
                return
            }

            newNumber.amount = Int32.random(in: 0...Int32.max)
            print("New Amount: \(newNumber.amount)")
            
            try? context.save()
            
            DispatchQueue.main.async {
                self.lastId = newNumber.objectID
                self.view.update(recordCount: self.currCount ?? -1 )
            }
        }
        
        return true
    }

    func maxQuery() {
        self.queue.async(execute: {
            let context = self.container.newBackgroundContext()
            context.performAndWait {
                //1.
                let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
                request.entity = NSEntityDescription.entity(forEntityName: "SomeNumber", in: context)
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

                var maxResult: Int32? = nil

                do {
                    //5.
                    if let result = try context.fetch(request) as? [[String: Int32]], let dict = result.first {
                       maxResult = dict[key]
                    }
                    
                } catch {
                    print("Failed to fetch max timestamp with error = \(error)")
                }
                
                if let maxResult = maxResult {
                    DispatchQueue.main.async {
                        self.view.alert(title: "Max Random", message: "The maximun generated number so far is \(maxResult)")
                    }
                }

            }

        })
    }
    
    func onDelete() {
        self.queue.async(execute: {
            let context = self.container.newBackgroundContext()
            context.performAndWait {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SomeNumber")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try self.container.persistentStoreCoordinator.execute(deleteRequest, with: context)
                    
                    DispatchQueue.main.async {
                        self.view.update(recordCount: self.currCount ?? -1 )
                    }
                } catch let error as NSError {
                    self.view.alert(title: "Error while removing", message: error.localizedDescription)
                }
            }
            
        })
    }
    
    func onLast() {
        guard let last = self.lastId else {
            self.view.alert(title: "Last ID", message: "Last ID not updated")
            return
        }
        
        if let object = try? self.container.viewContext.existingObject(with: last),
           let lastNumber = object as? SomeNumber {
            // do something with it
            let msg = "Amount: \(lastNumber.amount)"
            self.view.alert(title: "Last ID", message: msg)
        }
        else {
            self.view.alert(title: "Last ID", message: "No Object found")
        }
    }
}
