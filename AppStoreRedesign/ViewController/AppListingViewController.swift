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
  @IBOutlet weak var noInternetView: UIView!
  
  fileprivate var noInternetViewAnimating: Bool = false
  
  fileprivate var filterKeyword: String? = nil
  
  // Top Grossing Apps
  fileprivate var topGrossingApps: [AppObject] = []
  fileprivate var topGrossingAppsFiltered: [AppObject] = []
  
  // Top Free Apps
  
  // top application detail fetch size for each time
  fileprivate static let topAppDetailFetchSize = 10
  
  // this is ready for fetching the ID only, not ready for display!
  fileprivate var topAppIDs: [String] = []
  fileprivate var loadedIdsCount: Int = 0
  
  fileprivate var topAppsWithDetails: [AppObject] = []
  fileprivate var topAppsWithDetailsFiltered: [AppObject] = []
  
  private var isShowingGrossingAppSection: Bool {
    get {
      return topGrossingAppsFiltered.count > 0
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
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.showNoOrSlowInternetBanner), name: AppNotification.NoInternetOrSlowInternetNotification, object: nil)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    NotificationCenter.default.removeObserver(self, name: AppNotification.NoInternetOrSlowInternetNotification, object: nil)
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
      ref.recomputeFilterList()
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
    
    var endIndex = loadedIdsCount + AppListingViewController.topAppDetailFetchSize
    
    if endIndex >= topAppIDs.count {
      endIndex = topAppIDs.count
    }
    
    let appIDsToLoad = topAppIDs[
      startIndex..<endIndex
    ]
    
    let _ = iTunesDataSource.instance()?.fetchAppInfo(appIds: Array(appIDsToLoad)).done(on: DispatchQueue.main) { [weak self] (apps: [AppObject?]) in
      
      let validApps = apps.compactMap { $0 }
      
      guard let ref = self else {
        return
      }
      
      // enable load more features
      ref.appTableView?.setShouldShowInfiniteScrollHandler { _ -> Bool in
        return true
      }
      
      ref.appTableView?.beginUpdates()
      
      let beginSize = ref.topAppsWithDetailsFiltered.count
      let isShowingGrossingBeforeRecompute = ref.isShowingGrossingAppSection
      ref.topAppsWithDetails.append(contentsOf: validApps)
      ref.recomputeFilterList()
      let endingSize = ref.topAppsWithDetailsFiltered.count
      let isShowingGrossingAfterRecompute = ref.isShowingGrossingAppSection
      
      var rows: [IndexPath] = []
      for i in beginSize..<endingSize {
        rows.append(IndexPath(row: i + (isShowingGrossingAfterRecompute ? 1 : 0), section: 0))
      }
      ref.loadedIdsCount += AppListingViewController.topAppDetailFetchSize
      ref.appTableView?.insertRows(at: rows, with: .automatic)
      if isShowingGrossingBeforeRecompute && !isShowingGrossingAfterRecompute { // from showing to not showing
        ref.appTableView?.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
      } else if !isShowingGrossingBeforeRecompute && isShowingGrossingAfterRecompute { // from not showing to showing
        ref.appTableView?.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
      }
      ref.appTableView?.endUpdates()
      ref.appTableView?.finishInfiniteScroll()
    }
  }
  
  
  private func recomputeFilterList(searchText: String? = nil) {
    
    if let text = searchText {
      filterKeyword = text // update the keyword
    }
    
    guard let text = filterKeyword?.lowercased(), text != "" else {
      topGrossingAppsFiltered = Array(topGrossingApps)
      topAppsWithDetailsFiltered = Array(topAppsWithDetails)
      return
    }
    
    let computeFunc: (AppObject) -> Bool = {
      return $0.title?.lowercased().contains(text) ?? false ||
        $0.appCategory?.lowercased().contains(text) ?? false ||
        $0.author?.lowercased().contains(text) ?? false ||
        $0.summary?.lowercased().contains(text) ?? false
    }
    
    // recompute the list
    topGrossingAppsFiltered = topGrossingApps.filter(computeFunc)
    topAppsWithDetailsFiltered = topAppsWithDetails.filter(computeFunc)
    
  }
  
  @objc func showNoOrSlowInternetBanner() {
    
    guard !noInternetViewAnimating else {
      return
    }
    
    noInternetViewAnimating = true
    
    let beginTransform = CGAffineTransform(translationX: 0, y: -noInternetView.frame.height)
    
    // reset the starting position
    noInternetView.alpha = 0.0
    noInternetView.transform = beginTransform
    
    firstly {
      UIView.animate(.promise, duration: 0.5) { [weak self] in
        self?.noInternetView.alpha = 1.0
        self?.noInternetView.transform = CGAffineTransform.identity
      }
    }.then { _ in
      after(.seconds(2))
    }.then { [weak self] _ in
      UIView.animate(.promise, duration: 0.5) { [weak self] in
        self?.noInternetView.alpha = 0.0
        self?.noInternetView.transform = beginTransform
      }
    }.done { [weak self] _ in
      self?.noInternetViewAnimating = false
    }
  }
}

// MARK: extension - UITableViewDataSource
extension AppListingViewController: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1 // we will have only 1 section in this page
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return topAppsWithDetailsFiltered.count + (isShowingGrossingAppSection ? 1 : 0)
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
    
    guard realRowNumber < topAppsWithDetailsFiltered.count else {
      return UITableViewCell()
    }

    guard let cell = tableView.dequeueReusableCell(withIdentifier: AppTableViewCell.identifier, for: indexPath) as? AppTableViewCell else {
      return UITableViewCell()
    }
    let app = topAppsWithDetailsFiltered[realRowNumber]
    
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
    return topGrossingAppsFiltered.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    guard indexPath.item < topGrossingAppsFiltered.count else {
      return UICollectionViewCell()
    }
    
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GrossingAppCollectionViewCell.identifier, for: indexPath) as? GrossingAppCollectionViewCell else {
      return UICollectionViewCell()
    }
    
    let app = topGrossingAppsFiltered[indexPath.item]
    
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
    
    self.recomputeFilterList(searchText: searchText)
    self.appTableView?.reloadData()
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
}
