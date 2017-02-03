/*
 * Copyright 2015-2016 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
//
//  ChatViewController.swift
//  WhiskBot
//
//  Created by whisk on 1/17/17.
//  Copyright © 2017 Avery Lamp. All rights reserved.
//

import UIKit

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

