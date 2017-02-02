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
//  SplashViewController.swift
//  WhiskBot
//
//  Created by whisk on 1/17/17.
//  Copyright © 2017 Avery Lamp. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        backgroundImage.frame = CGRect(x: 0, y: 0, width: self.view.frame.width * 2, height: self.view.frame.height)
        backgroundImage.center.x = self.view.center.x + self.view.frame.width
        
        // Do any additional setup after loading the view.
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let positionPercent = scrollView.contentOffset.x / ( scrollView.contentSize.width - self.view.frame.width)
        backgroundImage.center.x = self.view.center.x + self.view.frame.width - self.view.frame.width * positionPercent
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func continueButtonClicked(_ sender: Any) {
        /*
        let chatVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatVC") as! ChatViewController
        
        self.present(chatVC, animated: true, completion: nil)
        */
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
