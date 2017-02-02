//
//  ChatViewController.swift
//  WhiskBot
//
//  Created by whisk on 1/17/17.
//  Copyright © 2017 Avery Lamp. All rights reserved.
//

import UIKit
import ConversationV1

class ChatViewController: UIViewController {
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var stopImage: UIImageView!

    @IBOutlet weak var microphoneImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        chatButton.tintColor = UIColor.white
        stopImage.alpha = 0.0
    }
    
    @IBAction func infoButtonClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let splashVC = storyboard.instantiateViewController(withIdentifier: "splashVC")
        self.present(splashVC, animated: true, completion: nil)
    }
    
    
    
    var circleLayer: CAShapeLayer? = nil
    @IBAction func chatButtonTouchDown(_ sender: Any) {
        if circleLayer == nil {
            circleLayer = CAShapeLayer()
            
            circleLayer?.path = UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: chatButton.frame.size), cornerRadius: chatButton.frame.width / 2).cgPath
            circleLayer?.lineWidth = 3
            circleLayer?.fillColor = nil
            circleLayer?.strokeColor = UIColor.green.cgColor
            circleLayer?.strokeEnd = 0.0
            CATransaction.setAnimationDuration(0.0)
            circleLayer?.strokeEnd = 0.0
            chatButton.layer.addSublayer(circleLayer!)
            
        }
        CATransaction.setAnimationDuration(1.0)
        circleLayer?.strokeEnd = 1.0
        UIView.animate(withDuration: 1.0) { 
            self.microphoneImage.alpha = 0.0
            self.stopImage.alpha = 1.0
        }
        print("Touch Down")
    }
    
    @IBAction func chatButtonDragExit(_ sender: Any) {
        CATransaction.setAnimationDuration(1.0)
        circleLayer?.strokeEnd = 0.0
        UIView.animate(withDuration: 1.0) {
            self.microphoneImage.alpha = 1.0
            self.stopImage.alpha = 0.0
        }
        print("Drag Exit")
    }
    
    @IBAction func chatButtonTouchUpInside(_ sender: Any) {
        CATransaction.setAnimationDuration(1.0)
        circleLayer?.strokeEnd = 0.0
        UIView.animate(withDuration: 1.0) {
            self.microphoneImage.alpha = 1.0
            self.stopImage.alpha = 0.0
        }
        print("Touch Up Inside")
    }
    
}

