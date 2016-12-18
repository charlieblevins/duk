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
    @IBOutlet weak var stopMsg: UISwitch!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.title = "Marker Guidelines"
        
        stopMsg.setOn(false, animated: false)

        styleContinueImg()
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
        
        let space: CGFloat = 10
        
        // top, left, bottom, right
        let img_width = img_view.frame.size.width
        continueBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -img_width/2, 0, img_width/2);
        
        let label_width = label.frame.size.width
        continueBtn.imageEdgeInsets = UIEdgeInsetsMake(0, label_width + space, 0, -label_width);
    }
    @IBAction func switchChange(_ sender: UISwitch) {
        let defaults = UserDefaults.standard
        let stopShowingMessage = sender.isOn
        defaults.set(stopShowingMessage, forKey: "stopMarkerGuidelineMessage")
    }
    
    @IBAction func continueTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
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

class ListItem: UILabel {
    required init (coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.commonInit()
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    func commonInit () {

        let item = NSMutableAttributedString(string: "- ")
        
        guard let content = self.text else {
            return
        }
        
        item.append(NSAttributedString(string: content))
        
        let para_style = NSMutableParagraphStyle()
        para_style.headIndent = 12
        
        let full_range = NSRange(location: 0, length: item.length)
        item.addAttribute("NSParagraphStyle", value: para_style, range: full_range)
        
        self.attributedText = item
    }
}
