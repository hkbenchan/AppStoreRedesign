//
//  AppObject.swift
//  AppStoreRedesign
//
//  Created by Chan Ho Pan on 5/7/2018.
//  Copyright © 2018 hpchan. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

/**
 * This is a class that resolve the data fetched directly from iTunes API
 */

class AppObject: Object {
  
  /**
   Use to distinguish where is the data from
   */
  @objc dynamic var source: Int = iTunesDataSource.DataSource.Unknown.rawValue
  
  /**
   RssFeed: Map to id.attribures.im:id; this is not BundleID!
   
   LookupAPI: Map to trackId
   */
  @objc dynamic var appId: String? = nil
  
  /**
   RssFeed: Map to im:name.label
   
   LookupAPI: Map to trackName
   */
  @objc dynamic var title: String? = nil
  
  /**
   RssFeed: Map to im:image.label; the iconURL will keep the image with largest height
   
   LookupAPI: Map to artworkUrl100 (512 is too large)
   */
  @objc dynamic var iconUrl: String? = nil
  
  /**
   RssFeed: Map to summary.label
   
   LookupAPI: Map to description
   */
  @objc dynamic var summary: String? = nil
  
  /**
   RssFeed: Map to category.attributes.label
   
   LookupAPI: Map to genres.first
   */
  @objc dynamic var appCategory: String? = nil

  // MARK: - Lookup API only property
  
  /**
   LookupAPI: Map to averageUserRating
   */
  @objc dynamic var rating: Double = 0
  
  /**
   LookupAPI: Map to userRatingCount
   */
  @objc dynamic var ratingCount: Int = 0
}

/**
 * Helper to cast direct JSON object into `AppObject
 */
extension AppObject {
  
  public static func parse(json: JSON, fromSource source: iTunesDataSource.DataSource = .Unknown) -> AppObject? {
    
    
    // given different source, we will have different logic to parse
    switch source {
    case .LookupAPI:
      return parseLookupAPI(json: json)
    case .RssFeed:
      return parseRssFeed(json: json)
    default:
      return nil // cannot parse
    }
  }
  
  private static func parseRssFeed(json: JSON) -> AppObject? {
    let appObject = AppObject()
    appObject.source = iTunesDataSource.DataSource.RssFeed.rawValue
    
    if let idDict = json["id"].dictionary, let attributesDict = idDict["attributes"]?.dictionary {
      appObject.appId = attributesDict["im:id"]?.string
    }
    
    if let imNameDict = json["im:name"].dictionary {
      appObject.title = imNameDict["label"]?.string
    }
    
    
    if let imageArray = json["im:image"].array {
      var maxSize = 0
      var url: String?
      for image: JSON in imageArray {
        if let attributesDict = image["attributes"].dictionary,
          let sizeStr = attributesDict["height"]?.string,
          let size = Int(sizeStr),
          maxSize < size
        {
          maxSize = size
          url = image["label"].string
        }
      }
      if maxSize != 0 {
        appObject.iconUrl = url
      }
    }
    
    if let summaryDict = json["summary"].dictionary {
      appObject.summary = summaryDict["label"]?.string
    }
    
    if let categoryDict = json["category"].dictionary, let attributesDict = categoryDict["attributes"]?.dictionary {
      appObject.appCategory = attributesDict["label"]?.string
    }
    
    return appObject
  }
  
  private static func parseLookupAPI(json: JSON) -> AppObject {
    
    let appObject = AppObject()
    appObject.source = iTunesDataSource.DataSource.RssFeed.rawValue
    
    if let appId = json["trackId"].number {
      appObject.appId = appId.stringValue
    }
    
    if let title = json["trackName"].string {
      appObject.title = title
    }
    
    if let summary = json["description"].string {
      appObject.summary = summary
    }
    
    if let genres = json["genres"].array, let firstGenre = genres.first, let category = firstGenre.string {
      appObject.appCategory = category
    }
    
    if let url = json["artworkUrl100"].string {
      appObject.iconUrl = url
    }
    
    if let rating = json["averageUserRating"].double {
      appObject.rating = rating
    }
    
    if let ratingCount = json["userRatingCount"].int {
      appObject.ratingCount = ratingCount
    }
    
    return appObject
  }
  
}
