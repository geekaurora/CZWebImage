//
//  CZImageCache.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 1/22/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

import UIKit
import CZUtils
import CZNetworking
import CZHttpFileCache

/**
 Thread safe local cache backed by DispatchQueue mutex lock/LRU queue, supports maxFileAge/maxCacheSize purging strategy
 */
class CZImageCache: CZBaseHttpFileCache {
  static func transformMetaDataToCachedData(_ data: Data?) -> UIImage? {
    return nil
  }
  public static let shared = CZImageCache()
  
  init() {
    super.init(transformMetaDataToCachedData: Self.transformMetaDataToCachedData)
  }
}
