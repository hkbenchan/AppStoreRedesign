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
  
  // Top Grossing Apps
  fileprivate var topGrossingApps: [AppObject] = []
  
  // Top Free Apps
  
  // top application detail fetch size for each time
  fileprivate static let topAppDetailFetchSize = 10
  
  // this is ready for fetching the ID only, not ready for display!
  fileprivate var topAppIDs: [String] = []
  fileprivate var loadedIdsCount: Int = 0
  
  fileprivate var topAppsWithDetails: [AppObject] = []
  
  private var isShowingGrossingAppSection: Bool {
    get {
      return topGrossingApps.count > 0
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    // we will get the app ids first
    self.loadDataFromSource()
    
    // bind the table view cell using nib file here
    let appTableViewCellNib = UINib(nibName: AppTableViewCell.identifier, bundle: Bundle.main)
    appTableView?.register(appTableViewCellNib, forCellReuseIdentifier: AppTableViewCell.identifier)
    
    let recommendationViewCellNib = UINib(nibName: RecommendationSectionTableViewCell.identifier, bundle: Bundle.main)
    appTableView?.register(recommendationViewCellNib, forCellReuseIdentifier: RecommendationSectionTableViewCell.identifier)
    
    appTableView?.addInfiniteScroll { [weak self] _ in
      guard let ref = self else {
        return
      }
      ref.loadMore()
    }
    appTableView?.setShouldShowInfiniteScrollHandler { _ -> Bool in
      return false
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  private func loadDataFromSource() {
    // top grossing apps
    let _ = iTunesDataSource.instance()?.topGrossingApplications().done(on: DispatchQueue.main) { [weak self] (apps: [AppObject]) -> Void in
      
      guard let ref = self else {
        return
      }
      
      ref.appTableView.beginUpdates()
      ref.topGrossingApps.removeAll()
      ref.topGrossingApps.append(contentsOf: apps)
      ref.appTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
      ref.appTableView.endUpdates()
    }
    
    
    // top free apps
    let _ = iTunesDataSource.instance()?.topFreeApplications().done(on: DispatchQueue.main) { [weak self] (apps: [AppObject]) -> Void in
      guard let ref = self else {
        return
      }
      
      ref.topAppIDs.removeAll()
      
      let appIDs = apps.map({ $0.appId }).compactMap {$0}
      
      ref.loadedIdsCount = 0
      ref.topAppIDs.append(contentsOf: appIDs)
      
      ref.loadMore()
    }
  }
  
  private func loadMore() {
    
    let startIndex = loadedIdsCount
    
    if startIndex >= topAppIDs.count {
      // no more data to load, stop infinite scrolling
      appTableView?.setShouldShowInfiniteScrollHandler { _ -> Bool in
        return false
      }
      appTableView?.finishInfiniteScroll()
      return // nothing to load
    }
    
    var endIndex = topAppsWithDetails.count + AppListingViewController.topAppDetailFetchSize
    
    if endIndex >= topAppIDs.count {
      endIndex = topAppIDs.count
    }
    
    let appIDsToLoad = topAppIDs[
      startIndex..<endIndex
    ]
    
    let _ = iTunesDataSource.instance()?.fetchAppInfo(appIDs: Array(appIDsToLoad)).done(on: DispatchQueue.main) { [weak self] (apps: [AppObject?]) in
      
      let validApps = apps.compactMap { $0 }
      
      guard let ref = self else {
        return
      }
      
      // enable load more features
      ref.appTableView?.setShouldShowInfiniteScrollHandler { _ -> Bool in
        return true
      }
      
      ref.appTableView?.beginUpdates()
      
      let beginSize = ref.topAppsWithDetails.count
      ref.topAppsWithDetails.append(contentsOf: validApps)
      let endingSize = ref.topAppsWithDetails.count
      
      var rows: [IndexPath] = []
      for i in beginSize..<endingSize {
        rows.append(IndexPath(row: i + 1, section: 0))
      }
      ref.loadedIdsCount += AppListingViewController.topAppDetailFetchSize
      ref.appTableView?.insertRows(at: rows, with: .automatic)
      
      ref.appTableView?.endUpdates()
      ref.appTableView?.finishInfiniteScroll()
    }
  }
  
}

// MARK: extension - UITableViewDataSource
extension AppListingViewController: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1 // we will have only 1 section in this page
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return topAppsWithDetails.count + (isShowingGrossingAppSection ? 1 : 0)
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isShowingGrossingAppSection && indexPath.row == 0 {
      guard let cell = tableView.dequeueReusableCell(withIdentifier: RecommendationSectionTableViewCell.identifier, for: indexPath) as? RecommendationSectionTableViewCell else {
        return UITableViewCell()
      }
      
      let nib = UINib(nibName: GrossingAppCollectionViewCell.identifier, bundle: Bundle.main)
      
      cell.registerCollectionViewNib(nib: nib, forCellWithReuseIdentifier: GrossingAppCollectionViewCell.identifier)
      cell.setCollectionViewDelegate(dataSourceDelegate: self)
      
      return cell
    }
    let realRowNumber = isShowingGrossingAppSection ? indexPath.row - 1 : indexPath.row
    
    guard realRowNumber < topAppsWithDetails.count else {
      return UITableViewCell()
    }

    guard let cell = tableView.dequeueReusableCell(withIdentifier: AppTableViewCell.identifier, for: indexPath) as? AppTableViewCell else {
      return UITableViewCell()
    }
    let app = topAppsWithDetails[realRowNumber]
    
    cell.viewSetup(realRowNumber + 1, data: app) // we display data with 1-based
    
    return cell
  }
  
}

// MARK: extension - UITableViewDelegate
extension AppListingViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if isShowingGrossingAppSection && indexPath.row == 0 {
      return 180
    }
    return 94 // hard set the height
  }
  
}

// MARK: extension - UICollectionViewDataSource
extension AppListingViewController: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return topGrossingApps.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    guard indexPath.item < topGrossingApps.count else {
      return UICollectionViewCell()
    }
    
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GrossingAppCollectionViewCell.identifier, for: indexPath) as? GrossingAppCollectionViewCell else {
      return UICollectionViewCell()
    }
    
    let app = topGrossingApps[indexPath.item]
    
    cell.viewSetup(data: app)
    
    return cell
  }
  
}

// MARK: extension - UICollectionViewDelegate
extension AppListingViewController: UICollectionViewDelegate {
  
  
  
}

// MARK: extension - UISearchBarDelegate
extension AppListingViewController: UISearchBarDelegate {
  
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    debugPrint("search text is changed to \(searchText)")
  }
  
}
