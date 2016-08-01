//
//  NounViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 5/29/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit


protocol EditNounDelegate {
    func nounsDidUpdate (nouns: String?)
}

class NounViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    @IBOutlet weak var NounList: UITableView!
    @IBOutlet weak var NounEntryField: UITextField!
    @IBOutlet weak var CellNounLabel: UILabel!
    
    // Raw data from AddMarkerController
    var nounsRaw: String? = nil
    
    // Primary data for table
    var allNouns: [NounData] = []
    
    // Possible delegate (AddMarkerController)
    var delegate: EditNounDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Put focus on text field
        NounEntryField.becomeFirstResponder()
        
        self.hideKeyboardWhenTappedAround()
        
        // Convert string of nouns to array
        if nounsRaw != nil {
            allNouns = nounsRaw!.componentsSeparatedByString(" ").map({
                return NounData(name: $0)
            })
        }

        // Do any additional setup after loading the view.
        NounEntryField.delegate = self
        NounList.delegate = self
        NounList.dataSource = self
        
        // display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        print("mem warning")
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NounViewController.dismissKeyboard))
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if NounEntryField.isFirstResponder() {
            return true
        }
        return false
    }

    
    // Called when "Edit" btn is tapped
    override func setEditing(editing: Bool, animated: Bool) {
        
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
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            allNouns.removeAtIndex(indexPath.row)
            NounList.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            // Update delegate nouns
            updateDelegateNouns()
        }
    }
    
    // Allow row re-order
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let itemToMove = allNouns[sourceIndexPath.row]
        allNouns.removeAtIndex(sourceIndexPath.row)
        allNouns.insert(itemToMove, atIndex: destinationIndexPath.row)
    }
    
    // Handle return tap
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        //textField.resignFirstResponder()
        
        // Get noun
        if textField.text != nil {
            
            let noun_name = applyNounFormat(textField.text!)
            
            allNouns.append(NounData(name: noun_name))
            
            NounList.beginUpdates()
            NounList.insertRowsAtIndexPaths([NSIndexPath(forRow: allNouns.count - 1, inSection: 0)], withRowAnimation: .Automatic)
            NounList.endUpdates()
            
            // Update delegate data
            updateDelegateNouns()
            
            // Clear field
            textField.text = ""
        }
        
        return true
    }
    
    func updateDelegateNouns () {
        
        // Ensure that delegate exists and has a Marker
        if self.delegate != nil {
            
            let nouns_arr = allNouns.map({
                return $0.name
            })
            
            let nounString = nouns_arr.joinWithSeparator(" ")
            
            if nounString == "" {
                self.delegate?.nounsDidUpdate(nil)
            } else {
                self.delegate?.nounsDidUpdate(nounString)
            }
        }
    }
    
    // Height for row
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    
    // Cell for row
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NounRow", forIndexPath: indexPath) as! NounTableViewCell
        
        cell.NounRowLabel.text = allNouns[indexPath.row].name
        cell.loadIconImage(allNouns[indexPath.row].name)
        
        return cell
    }
    
    // Number of sections
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // Number of rows
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allNouns.count
    }
    
    // Applies lower-case and dashes to incoming nouns
    func applyNounFormat (noun: String) -> String {
        
        // lowercase and dashes for spaces
        let lowercase_dashes = noun.lowercaseString.stringByReplacingOccurrencesOfString(" ", withString: "-")
        
        // Add # to beginning
        return "#\(lowercase_dashes)"
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
