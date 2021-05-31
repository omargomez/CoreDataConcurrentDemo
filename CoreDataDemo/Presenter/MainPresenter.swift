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
    func onNewNumber()
    
}

class MainPresenter {
    
    weak var view: MainView!
    var tasks: [DispatchWorkItem]
    var queue = DispatchQueue(label: "tasks-queue", qos: .default, attributes: .concurrent)
    let container: NSPersistentContainer
    
    init(view: MainView, container: NSPersistentContainer) {
        self.view = view
        self.container = container
        tasks = []
    }
    
    func addTask() {
        
        var aTask: DispatchWorkItem?
        let count = tasks.count
        
        aTask = DispatchWorkItem(block: { [weak self] in
            guard let task = aTask else {
                return
            }
            while self?.taskTick(task: task) ?? false {
                print("Task Running!!! \(count), main: \(Thread.isMainThread)")
                Thread.sleep(forTimeInterval: 1.0)
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
        context.perform {
            
            guard let newNumber = NSEntityDescription.insertNewObject(forEntityName: "SomeNumber", into: context) as? SomeNumber else {
                return
            }
            
            newNumber.amount = Int32.random(in: 0...1000)
            
            try? context.save()
            
            DispatchQueue.main.async {
                self.view.onNewNumber()
            }
        }
        
        return true
    }

}
