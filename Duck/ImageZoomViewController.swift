//
//  ImageZoomViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 4/18/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class ImageZoomViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    var fullImage: UIImage? = nil
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        if fullImage != nil {
            imageView.image = fullImage
        }
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        
        return self.imageView
        
    }
    
    // User tapped X button
    @IBAction func CloseTapped(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
