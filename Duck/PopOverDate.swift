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
    
    var choices = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14"]
    var finalChoice: String?
    var delegate: PopOverDateDelegate?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        
    }
    
    override func viewDidLoad () {
        super.viewDidLoad()
 
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
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return choices.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return addDaysFromNow(choices, row: row)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        finalChoice = addDaysFromNow(choices, row: row)
    }
    
    @IBAction func finishedPickingDate(sender: AnyObject) {
        
        // Pass date to super view
        delegate?.savePublishDate(finalChoice!)
        
        // Close popover
        dismissViewControllerAnimated(true, completion: nil)
    }
}
