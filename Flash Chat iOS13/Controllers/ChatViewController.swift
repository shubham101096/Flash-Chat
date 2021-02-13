//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    var messages: [Message] = []
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.title = K.appName
        tableView.dataSource = self
        let nib = UINib(nibName: K.cellNibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: K.cellIdentifier)
        loadMessages()
        messageTextfield.delegate = self
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        
        guard let msgBody = messageTextfield.text, let msgSender = Auth.auth().currentUser?.email else {
            return
        }
        
        db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.bodyField : msgBody, K.FStore.senderField : msgSender, K.FStore.dateField: Date().timeIntervalSince1970]) {
            (error) in
            if let e = error {
                print("Error saving data: \(e)")
            } else {
                print("Successfully saved data")
                DispatchQueue.main.async {
                    self.messageTextfield.text = ""
                }
            }
        }
        
    }
    
    @IBAction func logoutPressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    
    }
    
    func saveMessage() {
        guard let msgBody = messageTextfield.text, let msgSender = Auth.auth().currentUser?.email else {
            return
        }
        
        if msgBody == "" {
            return
        }
        
        db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.bodyField : msgBody, K.FStore.senderField : msgSender, K.FStore.dateField: Date().timeIntervalSince1970]) {
            (error) in
            if let e = error {
                print("Error saving data: \(e)")
            } else {
                print("Successfully saved data")
                DispatchQueue.main.async {
                    self.messageTextfield.text = ""
                }
            }
        }
    }
    
    func loadMessages() {
        
        let dbRef = db.collection(K.FStore.collectionName).order(by: K.FStore.dateField)
        dbRef.addSnapshotListener { (querySnapshot, error) in
            if let e = error {
                print("Error fetching data: \(e)")
            } else {
                self.messages = []
                if let querySnapshotDocs = querySnapshot?.documents {
                    for doc in querySnapshotDocs {
                        print(doc.data())
                        print(doc.data()[K.FStore.bodyField])
                        print(doc.data()[K.FStore.senderField])
                        
                        if let msgBody = doc.data()[K.FStore.bodyField] as? String, let msgSender = doc.data()[K.FStore.senderField] as? String {
                            self.messages.append(Message(sender: msgSender, body: msgBody))
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
}

extension ChatViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = messages[indexPath.row].body
        return cell
    }
    
    
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let msgBody = messageTextfield.text {
            if msgBody == "" {
                return false
            }
            saveMessage()
            return true
        }
        return false
    }
}

