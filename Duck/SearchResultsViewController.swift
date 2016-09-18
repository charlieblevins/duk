//
//  SearchResultsViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 9/7/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController {
    
    @IBOutlet weak var resultsLabel: UILabel!
    
    var parentController: MapViewController
    
    init(_ parent: MapViewController) {
        self.parentController = parent
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not allowed")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setMessage (_ message: String) {
        resultsLabel.text = message
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
