//
//  ViewController.swift
//  OWXcodeExtension
//
//  Created by whisk on 1/30/17.
//  Copyright © 2017 Avery Lamp. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func instructionsClicked(_ sender: Any) {
        let url = URL(string: "https://github.ibm.com/Avery-Lamp/openwhisk-xcode")
        NSWorkspace.shared().open(url!)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

