//
//  ViewController.swift
//  CoreDataDemo
//
//  Created by Omar Gomez on 28/05/21.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    var presenter: MainPresenter!
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var recordCountLabel: UILabel!
    
    var delegate: AppDelegate {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("No container")
        }
        
        return delegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.presenter = MainPresenter(view: self, container: delegate.persistentContainer)
    }

    @IBAction func onAddAction(_ sender: Any) {
        self.presenter.addTask()
    }
        
    @IBAction func onRemoveAction(_ sender: Any) {
        self.presenter.removeTask()
    }
}

extension ViewController: MainView {
    
    func update(count: Int) {
        self.countLabel.text = String(count)
    }
    
    func onNewNumber() {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SomeNumber")
        do {
            let count = try delegate.persistentContainer.viewContext.count(for: fetchRequest)
            self.recordCountLabel.text = String(count)
        } catch {
            print(error.localizedDescription)
        }
    }
    
}

