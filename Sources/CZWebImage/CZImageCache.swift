import UIKit
import CZUtils
import CZNetworking
import CZHttpFileCache

/**
 Thread safe local cache backed by DispatchQueue mutex lock/LRU queue, supports maxFileAge/maxCacheSize purging strategy
 */
class CZImageCache: CZBaseHttpFileCache {
  public static let shared = CZImageCache()

  /// Data transformer that transforms from `data` to  UIImage.
  static func transformMetaDataToCachedData(_ data: Data?) -> UIImage? {
    guard let data = data else { return nil }
    let image = UIImage(data: data)
    return image
  }
  
  init() {
    super.init(transformMetaDataToCachedData: Self.transformMetaDataToCachedData)
  }
  
  override func cacheCost(forImage image: AnyObject) -> Int {
    guard let image = (image as? UIImage).assertIfNil else {
      return 0
    }
    return Int(image.size.height * image.size.width * image.scale * image.scale)
  }
}
