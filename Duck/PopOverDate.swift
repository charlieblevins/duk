//
//  PopOverDate.swift
//  Duck
//
//  Created by Charlie Blevins on 2/7/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

protocol PopOverDateDelegate {
    func savePublishDate(chosenTime: String)
}

class PopOverDate: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var doneBtn: UIButton!
    
    var choices = ["One", "two", "three"]
    var delegate: PopOverDateDelegate?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        
    }
    
    override func viewDidLoad () {
        super.viewDidLoad()
 
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return choices.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return choices[row]
    }
    
    @IBAction func finishedPickingDate(sender: AnyObject) {
        
        // Pass date to super view
        delegate?.savePublishDate("Test choice")
        
        // Close popover
        dismissViewControllerAnimated(true, completion: nil)
    }
}
