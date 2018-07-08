//
//  TopGrossingApps.swift
//  AppStoreRedesign
//
//  Created by Chan Ho Pan on 9/7/2018.
//  Copyright © 2018 hpchan. All rights reserved.
//

import Foundation
import RealmSwift

class TopGrossingApp: Object {
  @objc dynamic var position: Int = 0
  @objc dynamic var appId: String?
  
  override static func primaryKey() -> String? {
    return "position"
  }
}
