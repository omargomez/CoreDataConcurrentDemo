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
    
}

class MainPresenter {
    
    weak var view: MainView!
    var tasks: [DispatchWorkItem]
    var queue = DispatchQueue(label: "tasks-queue", qos: .default, attributes: .concurrent)
    var lastId: NSManagedObjectID?
    let numberService: SomeNumberRepository = SomeNumberRepositoryImpl()

    init(view: MainView) {
        self.view = view
        tasks = []
    }
    
    func viewDidLoad() {
        self.view.update(recordCount: (try? self.numberService.count()) ?? -1 )
        self.view.update(count: 0 )
    }
    
    func addTask() {
        
        var aTask: DispatchWorkItem?
        
        aTask = DispatchWorkItem(block: { [weak self] in
            guard let task = aTask else {
                return
            }
            while !task.isCancelled {
                self?.taskTick()
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
    
    func taskTick() {
        numberService.insert(amount: Int32.random(in: 0...Int32.max), { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let newID):
                print("New Number added: \(newID)")
                DispatchQueue.main.async {
                    self.lastId = newID
                    self.view.update(recordCount: (try? self.numberService.count()) ?? -1 )
                }
            case .failure(let error):
                print("Error while adding: \(error.localizedDescription)")
            }
        })
    }
    
    func maxQuery() {
        self.numberService.maxAmount({ [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let maxValue):
                DispatchQueue.main.async {
                    self.view.alert(title: "Max Random", message: "The maximun generated number so far is \(maxValue)")
                }
            case .failure(let error):
                print("Error while getting max val: \(error.localizedDescription)")
            }
        })
    }
    
    func onDelete() {
        self.numberService.deleteAll({ [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.lastId = nil
                    self.view.update(recordCount: (try? self.numberService.count()) ?? -1 )
                }
            case .failure(let error):
                print("Error while removind all records: \(error.localizedDescription)")
            }
        })
    }
    
    func onLast() {
        guard let last = self.lastId else {
            self.view.alert(title: "Last ID", message: "Last ID not updated")
            return
        }
        
        do {
            if let lastNumber = try self.numberService.someNumber(withId: last) {
                let msg = "Amount: \(lastNumber.amount)"
                self.view.alert(title: "Last ID", message: msg)
            } else {
                self.view.alert(title: "Last ID", message: "No Object found")
            }
        } catch {
            self.view.alert(title: "Error", message: error.localizedDescription)
        }
    }
    
    func batchInsert() {
        
        let amounts: [Int32] = (0...Int.random(in: 700...900))
           .lazy
            .map { _ in Int32.random(in: 0...Int32.max) }

        numberService.batchInsert(amounts: amounts, { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let idArray):
                    self.lastId = idArray.last
                    self.view.update(recordCount: (try? self.numberService.count()) ?? -1 )
                case .failure(let error):
                    self.view.alert(title: "Error while batch adding", message: error.localizedDescription)
                }
            }
        })
        
    }
}
