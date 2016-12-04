//
//  MarkerGuidelinesViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 12/4/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class MarkerGuidelinesViewController: UIViewController {

    @IBOutlet weak var continueBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        continueBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -(continueBtn.imageView?.frame.size.width)!, 0, (continueBtn.imageView?.frame.size.width)!);
        continueBtn.imageEdgeInsets = UIEdgeInsetsMake(0, (continueBtn.titleLabel?.frame.size.width)!, 0, -(continueBtn.titleLabel?.frame.size.width)!);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func styleContinueImg () {
        
        guard let img_view = continueBtn.imageView else {
            return
        }
        
        guard let label = continueBtn.titleLabel else {
            return
        }
        
        let img_width = img_view.frame.size.width
        continueBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -img_width, 0, img_width);
        
        let label_width = label.frame.size.width
        continueBtn.imageEdgeInsets = UIEdgeInsetsMake(0, label_width, 0, -label_width);
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
