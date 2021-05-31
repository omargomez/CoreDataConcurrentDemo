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
        self.presenter.viewDidLoad()
    }

    @IBAction func onAddAction(_ sender: Any) {
        self.presenter.addTask()
    }
        
    @IBAction func onRemoveAction(_ sender: Any) {
        self.presenter.removeTask()
    }
    
    @IBAction func onMaxQuery(_ sender: Any) {
        self.presenter.maxQuery()
    }
    
    @IBAction func onDelete(_ sender: Any) {
        self.presenter.onDelete()
    }
    
    @IBAction func onLast(_ sender: Any) {
        self.presenter.onLast()
    }
    
}

extension ViewController: MainView {
    
    func update(count: Int) {
        self.countLabel.text = String(count)
    }
    
    func update(recordCount: Int) {
        self.recordCountLabel.text = String(recordCount)
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
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)

    }
    
}

