//
//  ViewController.swift
//  AppStoreRedesign
//
//  Created by Chan Ho Pan on 5/7/2018.
//  Copyright © 2018 hpchan. All rights reserved.
//

import UIKit
import PromiseKit

class AppListingViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    iTunesDataSource.instance()?.topGrossingApplications().done { (apps: [AppObject]) -> Void in
      for app: AppObject in apps {
        print("app data received: \(app)")
      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

