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
   Map to id.attribures.im:id; this is not BundleID!
  */
  @objc dynamic var appId: String? = nil
  
  /**
   Map to im:name.label
   */
  @objc dynamic var title: String? = nil
  
  /**
   Map to im:image.label; the iconURL will keep the image with largest height
   */
  @objc dynamic var iconUrl: String? = nil
  
  /**
   Map to summary.label
   */
  @objc dynamic var summary: String? = nil
  
  /**
   Map to category.attributes.label
   */
  @objc dynamic var appCategory: String? = nil
}

/**
 * Helper to cast direct JSON object into `AppObject
 */
extension AppObject {
  
  public static func parse(json: JSON) -> AppObject? {
    
    let appObject = AppObject()
    
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
  
}
