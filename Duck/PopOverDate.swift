//
//  PopOverDate.swift
//  Duck
//
//  Created by Charlie Blevins on 2/7/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

protocol PopOverDateDelegate {
    func savePublishDate(chosenTime: String?)
}

class PopOverDate: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var choices = ["Now", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14"]

    var choice: String?
    var delegate: PopOverDateDelegate?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad () {
        super.viewDidLoad()
        
        // Set default to previously chosen value or first "Now"
        if choice != nil {
           self.setDefault(choice!)
        } else {
            choice = choices[0]
        }
    }
    
    // Add " day(s) from now" to each day number
    func addDaysFromNow (choicesArr: [String], row: Int) -> String {
        let item = choices[row]
        
        // Handle plurality
        if item == "1" {
            return "\(item) day from now"
        } else {
            return "\(choices[row]) days from now"
        }
    }
    
    func setDefault (defaultChoice: String) {
        
        // Remove " days from now" before lookup
        let choiceNumberOnly = defaultChoice.stringByReplacingOccurrencesOfString(" days from now", withString: "")
        let defaultIndex = choices.indexOf(choiceNumberOnly)
        
        if defaultIndex != nil {
            pickerView.selectRow(defaultIndex!, inComponent: 0, animated: false)
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return choices.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if choices[row] == "Now" {
            return "Now"
        } else {
            return addDaysFromNow(choices, row: row)
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        choice = addDaysFromNow(choices, row: row)
    }
    
    @IBAction func finishedPickingDate(sender: AnyObject) {
        
        // Pass date to super view
        if choice != nil {
            delegate?.savePublishDate(choice!)
        } else {
            print("choice var is empty!")
        }
        
        // Close popover
        dismissViewControllerAnimated(true, completion: nil)
    }
}
