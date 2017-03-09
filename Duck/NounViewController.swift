//
//  NounViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 5/29/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit


protocol EditNounDelegate {
    func nounsDidUpdate (_ nouns: String?)
}

class NounViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    @IBOutlet weak var NounList: UITableView!
    @IBOutlet weak var NounEntryField: UITextField!
    @IBOutlet weak var CellNounLabel: UILabel!
    @IBOutlet weak var NounListBottomConstraint: NSLayoutConstraint!
    
    // Raw data from AddMarkerController
    var nounsRaw: String? = nil
    
    // Primary data for table
    var allNouns: [NounData] = []
    
    // Possible delegate (AddMarkerController)
    var delegate: EditNounDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        // Convert string of nouns to array
        if nounsRaw != nil {
            allNouns = nounsRaw!.components(separatedBy: " ").map({
                return NounData(name: $0)
            })
        }

        // Do any additional setup after loading the view.
        NounEntryField.delegate = self
        NounList.delegate = self
        NounList.dataSource = self
        
        // display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Put focus on text field - needs to happen after data population
        NounEntryField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        print("mem warning")
    }
    
    func keyboardWillShow (notification: Notification) {
        animateHeightWithNotification(notification, action: "add")
        scrollToBottom()
    }
    
    func keyboardWillHide (notification: Notification) {
        animateHeightWithNotification(notification, action: "subtract")
    }
    
    func scrollToBottom () {
        let total = self.NounList.numberOfRows(inSection: 0)
        
        guard total > 0 else {
            print("cannot scrollToBottom: now nouns in view")
            return
        }
        
        let last_index = total - 1
        let last_path = IndexPath(row: last_index, section: 0)
        self.NounList.scrollToRow(at: last_path, at: .bottom, animated: true)
    }
    
    func animateHeightWithNotification (_ notification: Notification, action: String) {
        
        guard let user_info = notification.userInfo else {
            print("expected user info in notification")
            return
        }
        
        let duration = (user_info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let end_frame = (user_info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let converted_end_frame = self.view.convert(end_frame, to: self.NounList)
        let raw_animation_curve = (user_info[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue << 16
        let animation_curve = UIViewAnimationOptions.init(rawValue: UInt(raw_animation_curve))
        
        if (action == "subtract") {
            self.NounListBottomConstraint.constant = self.NounListBottomConstraint.constant - converted_end_frame.height
        } else {
            self.NounListBottomConstraint.constant = self.NounListBottomConstraint.constant + converted_end_frame.height
        }
        
        UIView.animate(withDuration: duration, delay: 0.0, options: [.beginFromCurrentState, animation_curve], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NounViewController.dismissKeyboard))
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if NounEntryField.isFirstResponder {
            return true
        }
        return false
    }

    
    // Called when "Edit" btn is tapped
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        // Toggles the edit button state
        super.setEditing(editing, animated: animated)
        
        // Toggles the actual editing actions appearing on a table view
        NounList.setEditing(editing, animated: true)
        
        // Refresh delegate nouns on editing complete
        if editing == false {
            updateDelegateNouns()
        }
    }
    
    // Handle edit actions
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            allNouns.remove(at: (indexPath as NSIndexPath).row)
            NounList.deleteRows(at: [indexPath], with: .automatic)
            
            // Update delegate nouns
            updateDelegateNouns()
        }
    }
    
    // Allow row re-order
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove = allNouns[(sourceIndexPath as NSIndexPath).row]
        allNouns.remove(at: (sourceIndexPath as NSIndexPath).row)
        allNouns.insert(itemToMove, at: (destinationIndexPath as NSIndexPath).row)
    }
    
    // Handle return tap
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //textField.resignFirstResponder()
        
        // Get noun
        if textField.text != nil && textField.text != "" {
            
            let noun_name = applyNounFormat(textField.text!)
            
            allNouns.append(NounData(name: noun_name))
            
            NounList.beginUpdates()
            NounList.insertRows(at: [IndexPath(row: allNouns.count - 1, section: 0)], with: .automatic)
            NounList.endUpdates()
            
            // Update delegate data
            updateDelegateNouns()
            
            // Clear field
            textField.text = ""
            
            scrollToBottom()
        }
        
        return true
    }
    
    func updateDelegateNouns () {
        
        // Ensure that delegate exists and has a Marker
        if self.delegate != nil {
            
            let nouns_arr = allNouns.map({
                return $0.name
            })
            
            let nounString = nouns_arr.joined(separator: " ")
            
            if nounString == "" {
                self.delegate?.nounsDidUpdate(nil)
            } else {
                self.delegate?.nounsDidUpdate(nounString)
            }
        }
    }
    
    // Height for row
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    // Cell for row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NounRow", for: indexPath) as! NounTableViewCell
        
        cell.NounRowLabel.text = allNouns[(indexPath as NSIndexPath).row].name
        cell.iconView.setNoun(allNouns[(indexPath as NSIndexPath).row].name)
        
        return cell
    }
    
    // Number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allNouns.count
    }
    
    // Applies lower-case and dashes to incoming nouns
    func applyNounFormat (_ noun: String) -> String {
        
        // lowercase and dashes for spaces
        return noun.lowercased().replacingOccurrences(of: " ", with: "-")
    }
}


// Make Noun class that contains a name (string)
// and an image (defaults to loader, eventually gets
// marker image
class NounData {
    
    var name: String
    var image: UIImage? = nil
    
    init (name: String) {
        self.name = name
    }
}
