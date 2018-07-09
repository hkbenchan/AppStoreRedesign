//
//  iTunesDataSource.swift
//  AppStoreRedesign
//
//  Created by Chan Ho Pan on 5/7/2018.
//  Copyright © 2018 hpchan. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftyJSON

fileprivate let HOST = "itunes.apple.com"
fileprivate let TopGrossingApplicationSearchLimit = 10
fileprivate let TopFreeApplicationSearchLimit = 100

class iTunesDataSource {
  
  public enum DataSource: Int {
    case Unknown = 0
    case RssFeed = 1
    case LookupAPI = 2
  }
  
  // class methods
  
  // we will have this manager have to monitor the network status
  fileprivate static var reachabilityManager: NetworkReachabilityManager? = nil
  
  fileprivate static var _shareInstance: iTunesDataSource? = nil
  
  public static func instance() -> iTunesDataSource? {
    if _shareInstance == nil {
      _shareInstance = iTunesDataSource()
    }
    return _shareInstance
  }
  
  // instance methods
  let manager: SessionManager
  
  public init() {
    // during init, we will setup the reachability
    if let _ = iTunesDataSource.reachabilityManager {
      // do nothing
    } else {
      iTunesDataSource.reachabilityManager = NetworkReachabilityManager(host: HOST)
      iTunesDataSource.reachabilityManager?.listener = { status in
        debugPrint("Network status changed: \(status)")
        // TODO: send notification to notify the network status change
        if status == NetworkReachabilityManager.NetworkReachabilityStatus.notReachable {
          NotificationCenter.default.post(name: AppNotification.NoInternetOrSlowInternetNotification, object: nil)
        }
      }
      iTunesDataSource.reachabilityManager?.startListening()
    }
    
    // we need to consider the MitM, lets assume we will have the default eval first and then we will improve with stronger validation methods
    // TODO: stronger validation methods
    let trustPolicyManager = ServerTrustPolicyManager(policies: [HOST : ServerTrustPolicy.performDefaultEvaluation(validateHost: true)])
    
    let configuration = URLSessionConfiguration.default
    
    manager = Alamofire.SessionManager(configuration: configuration, serverTrustPolicyManager: trustPolicyManager)
  }
  
  public func topGrossingApplications() -> Promise<[AppObject]> {
    
    let urlString = "https://\(HOST)/hk/rss/topgrossingapplications/limit=\(TopGrossingApplicationSearchLimit)/json"
    guard let url = try? urlString.asURL() else {
      return Promise(error: PromiseErrors.invalidUrl)
    }
    
    return fetchApplicationList(onURL: url).then { (apps: [AppObject]) -> Promise<[AppObject]> in
      
      // save the data into Realm
      RealmDataSource.instance().saveTopGrossingApplications(apps: apps)
      
      return Promise.value(apps)
    }.recover { [weak self] (err: Error) -> Promise<[AppObject]> in
      self?.processError(err: err)
      return RealmDataSource.instance().topGrossingApplications()
    }
  }
  
  public func topFreeApplications() -> Promise<[AppObject] > {
    let urlString = "https://\(HOST)/hk/rss/topfreeapplications/limit=\(TopFreeApplicationSearchLimit)/json"
    guard let url = try? urlString.asURL() else {
      return Promise(error: PromiseErrors.invalidUrl)
    }
    
    return fetchApplicationList(onURL: url)
  }
  
  private func fetchApplicationList(onURL url: URL) -> Promise<[AppObject]> {
    return manager.request(url, method: .get).responseJSON().then { body -> Promise<[AppObject]> in
      let json = JSON(body.json)
      
      guard let feed = json["feed"].dictionary, let entries = feed["entry"]?.array else {
        return Promise(error: PromiseErrors.noResult)
      }
      
      var apps: [AppObject] = []
      for entry: JSON in entries {
        if let app = AppObject.parse(json: entry, fromSource: .RssFeed) {
          apps.append(app)
        }
      }
      
      return Promise<[AppObject]>.value(apps)
    }
  }
  
  /**
   Given a list of appIDs, it will be send to lookup API to fetch full details.
   The return list will be sorted based on the ordering inside appIDs.
   
   Any invalid AppID will result in a nil object in the array
   */
  public func fetchAppInfo(appIds: [String]) -> Promise<[AppObject?]> {
    
    let urlString = "https://\(HOST)/hk/lookup"
    
    var components = URLComponents(string: urlString)
    components?.queryItems = [ URLQueryItem(name: "id", value: appIds.joined(separator: ",")) ]
    
    guard let url = components?.url else {
      return Promise(error: PromiseErrors.invalidUrl)
    }
    return manager.request(url, method: .get).responseString().then { body -> Promise<[AppObject]> in
      debugPrint("received body")
      let json = JSON.init(parseJSON: body.string)
      
      guard let results = json["results"].array else {
        return Promise.value([])
      }
      
      var apps: [AppObject] = []
      for result: JSON in results {
        if let app = AppObject.parse(json: result, fromSource: .LookupAPI) {
          apps.append(app)
        }
      }
      RealmDataSource.instance().saveAppObjects(apps: apps)
      return Promise.value(apps)
    }.then { (apps: [AppObject]) -> Promise<[AppObject?]> in
      let sorted = appIds.map { appId in
        return apps.first { $0.appId == appId }
      }
      return Promise.value(sorted)
    }.recover { [weak self] (err: Error) -> Promise<[AppObject?]> in
      self?.processError(err: err)
      return RealmDataSource.instance().loadAppsDetail(appIds: appIds)
    }
    
  }
  
  private func processError(err: Error) {
    let error = err as NSError
    if error.domain == URLError.errorDomain {
      switch (error.code) {
      case URLError.notConnectedToInternet.rawValue,
           URLError.cannotFindHost.rawValue,
           URLError.cannotLoadFromNetwork.rawValue,
           URLError.timedOut.rawValue,
           URLError.networkConnectionLost.rawValue:
        NotificationCenter.default.post(name: AppNotification.NoInternetOrSlowInternetNotification, object: nil)
        break
      default:
        break
      }
      
    }
  }
  
  deinit {
    iTunesDataSource._shareInstance = nil
    iTunesDataSource.reachabilityManager?.stopListening()
  }
}
