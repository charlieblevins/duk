//
//  NounViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 5/29/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class NounViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var NounList: UITableView!
    @IBOutlet weak var NounEntryField: UITextField!
    @IBOutlet weak var CellNounLabel: UILabel!
    
    var allNouns: [NounData] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NounEntryField.delegate = self
        NounList.delegate = self
        NounList.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // Handle return tap
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        // Get noun
        if textField.text != nil {
            allNouns.append(NounData(name: textField.text!))
            NounList.beginUpdates()
            NounList.insertRowsAtIndexPaths([NSIndexPath(forRow: allNouns.count - 1, inSection: 0)], withRowAnimation: .Automatic)
            NounList.endUpdates()
        }
        
        return true
    }
    
    // Height for row
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    
    // Cell for row
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NounRow", forIndexPath: indexPath) as! NounTableViewCell
        
        cell.NounRowLabel.text = allNouns[indexPath.row].name
        cell.NounRowActivity.startAnimating()
        
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
