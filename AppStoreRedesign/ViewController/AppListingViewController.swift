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
  
  // IBOutlets
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var appTableView: UITableView!
  
  // top application detail fetch size for each time
  fileprivate static let topAppDetailFetchSize = 10
  
  // this is ready for fetching the ID only, not ready for display!
  fileprivate var topAppIDs: [String] = []
  
  fileprivate var topAppsWithDetails: [AppObject] = []
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    let _ = iTunesDataSource.instance()?.topFreeApplications().done(on: DispatchQueue.main) { [weak self] (apps: [AppObject]) -> Void in
      guard let ref = self else {
        return
      }
      
      ref.topAppIDs.removeAll()
      
      let appIDs = apps.map({ $0.appId }).compactMap {$0}
      
      ref.topAppIDs.append(contentsOf: appIDs)
      
      ref.loadMore()
    }
    
    // bind the table view cell using nib file here
    let appTableViewCellNib = UINib(nibName: "AppTableViewCell", bundle: Bundle.main)
    appTableView?.register(appTableViewCellNib, forCellReuseIdentifier: AppTableViewCell.identifier)

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  
  private func loadMore() {
    
    let startIndex = topAppsWithDetails.count
    
    if startIndex >= topAppIDs.count {
      return // nothing to load
    }
    var endIndex = topAppsWithDetails.count + AppListingViewController.topAppDetailFetchSize
    
    if endIndex >= topAppIDs.count {
      endIndex = topAppIDs.count - 1
    }
    
    let appIDsToLoad = topAppIDs[
      startIndex..<endIndex
    ]
    
    let _ = iTunesDataSource.instance()?.fetchAppInfo(appIDs: Array(appIDsToLoad)).done(on: DispatchQueue.main) { [weak self] (apps: [AppObject?]) in
      
      let validApps = apps.compactMap { $0 }
      
      guard let ref = self else {
        return
      }
      
      ref.topAppsWithDetails.append(contentsOf: validApps)
      ref.appTableView?.reloadData()
    }
  }
  
}

// MARK: extension - UITableViewDataSource
extension AppListingViewController: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1 // we will have only 1 section in this page
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return topAppsWithDetails.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard indexPath.row < topAppsWithDetails.count else {
      return UITableViewCell()
    }

    guard let cell = tableView.dequeueReusableCell(withIdentifier: AppTableViewCell.identifier, for: indexPath) as? AppTableViewCell else {
      return UITableViewCell()
    }
    let app = topAppsWithDetails[indexPath.row]
    
    cell.viewSetup(indexPath.row + 1, data: app) // we display data with 1-based
    
    return cell
  }
  
}

// MARK: extension - UITableViewDelegate
extension AppListingViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 94 // hard set the height
  }
  
}

// MARK: extension - UISearchBarDelegate
extension AppListingViewController: UISearchBarDelegate {
  
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    debugPrint("search text is changed to \(searchText)")
  }
  
}