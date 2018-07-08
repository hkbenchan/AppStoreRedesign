//
//  RealmDataSource.swift
//  AppStoreRedesign
//
//  Created by Chan Ho Pan on 9/7/2018.
//  Copyright © 2018 hpchan. All rights reserved.
//

import Foundation
import PromiseKit
import RealmSwift

class RealmDataSource {
  
  fileprivate static let _instance = RealmDataSource()
  
  fileprivate let realm: Realm?
  
  public class func instance() -> RealmDataSource {
    return _instance
  }
  
  public init() {
    let config = Realm.Configuration(schemaVersion: 1, migrationBlock: nil, deleteRealmIfMigrationNeeded: true)
    
    Realm.Configuration.defaultConfiguration = config
    
    realm = try? Realm()
  }
  
  public func topGrossingApplications() -> Promise<[AppObject]> {
    
    // fetch the list of grossing applications
    return Promise<[TopGrossingApp]>(resolver: { (resolver) in
      guard let grossingAppsInRealm = realm?.objects(TopGrossingApp.self)
        .filter("position >= 0 AND position < 10")
        .sorted(byKeyPath: "position", ascending: true) else {
          resolver.fulfill([])
          return
      }
      
      var grossingApps: [TopGrossingApp] = []
      for i in 0..<10 {
        if grossingAppsInRealm.count > i {
          grossingApps.append(grossingAppsInRealm[i])
        }
      }
      
      resolver.fulfill(grossingApps)
    }).then { [weak self] (grossingApps) -> Promise<[AppObject]> in
      
      if grossingApps.count == 0 {
        return Promise.value([])
      }
      
      guard let ref = self else {
        return Promise.value([])
      }
      
      let appIds = grossingApps.map { $0.appId }.compactMap { $0 }
      let predicate = NSPredicate(format: "appId in { %@ }", appIds.joined(separator: ","))
      guard let appsInRealm = ref.realm?.objects(AppObject.self)
        .filter(predicate) else {
          return Promise.value([])
      }
      
      var apps: [AppObject] = []
      
      appIds.forEach { appId in
        let app = appsInRealm.filter("appId = '\(appId)'")
        if app.count > 0 {
          apps.append(app[0])
        }
      }
      
      return Promise.value(apps)
    }


    
    
  }
  
  public func saveTopGrossingApplications(apps: [AppObject]) {
    
    // save any grossing applications
    realm?.beginWrite()
    apps.forEach { app in
      if let res = realm?.objects(AppObject.self).filter("appId = '\(app.appId ?? "0")'") {
        if res.count == 0 {
          // insert
          realm?.add(app)
        }
      }
    }
    
    try? realm?.commitWrite()
    
    // save the list of grossing applications
    
    realm?.beginWrite()
    
    apps.map({ app -> TopGrossingApp in
      let grossingApp = TopGrossingApp()
      grossingApp.appId = app.appId
      grossingApp.position = apps.index(of: app) ?? -1
      return grossingApp
    }).forEach { (topGrossingApp: TopGrossingApp) in
      realm?.add(topGrossingApp, update: true)
    }
    
    try? realm?.commitWrite()
  }
  
  public func loadAppsDetail(appIds: [String]) -> Promise<[AppObject?]> {
    
    return Promise<[AppObject?]>(resolver: { (resolver) in
      if appIds.count == 0 {
        resolver.fulfill(appIds.map { _ in return nil } )
        return
      }
      
      let predicate = NSPredicate(format: "appId IN %@ AND source = %d", appIds, iTunesDataSource.DataSource.LookupAPI.rawValue)
      guard let appsInRealm = realm?.objects(AppObject.self)
        .filter(predicate) else {
          resolver.fulfill(appIds.map { _ in return nil } )
          return
      }
      
      var apps: [AppObject?] = []
      
      appIds.forEach { appId in
        let app = appsInRealm.filter("appId = '\(appId)'")
        if app.count > 0 {
          apps.append(app[0])
        } else {
          apps.append(nil)
        }
      }
      
      resolver.fulfill(apps)
    })
    
  }
  
  public func saveAppObjects(apps: [AppObject]) {
    realm?.beginWrite()
    apps.forEach { app in
      realm?.add(app, update: (app.source == iTunesDataSource.DataSource.LookupAPI.rawValue))
    }
    try? realm?.commitWrite()
  }

}
