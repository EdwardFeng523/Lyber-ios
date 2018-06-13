//
//  ViewController.swift
//  Lyber
//
//  Created by Edward Feng on 6/11/18.
//  Copyright © 2018 Edward Feng. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var from: UITextField!
    
    @IBOutlet weak var to: UITextField!
    
    @IBAction func lyber(_ sender: Any) {
    }
    
    @IBOutlet weak var display: UIScrollView!
    
}

