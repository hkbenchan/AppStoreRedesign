//
//  PromiseErrors.swift
//  AppStoreRedesign
//
//  Created by Chan Ho Pan on 5/7/2018.
//  Copyright © 2018 hpchan. All rights reserved.
//

import Foundation


enum PromiseErrors: Error {
  // network related errors
  case invalidUrl
  case noResponse
  case noResult
}
