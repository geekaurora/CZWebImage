import UIKit
import CZUtils
import CZNetworking
import CZHttpFile

/**
 Web image manager maintains asynchronous image downloading tasks
 */
@objc open class CZWebImageManager: NSObject {
  public static let shared: CZWebImageManager = CZWebImageManager()
  private var downloader: CZImageDownloader
  public private(set) var cache: CZImageCache
  
  public override init() {
    cache = CZImageCache()
    downloader = CZImageDownloader(cache: cache)
    super.init()
  }
  
  public func downloadImage(with url: URL,
                            cropSize: CGSize? = nil,
                            priority: Operation.QueuePriority = .normal,
                            completion: @escaping CZImageDownloderCompletion) {
    CZSignpostHelper.shared.start()
    
    cache.getCachedFile(withUrl: url) { [weak self] (image) in
      guard let `self` = self else { return }
      
      // Load from local disk
      if let image = image {
        MainQueueScheduler.sync {
          completion(image, nil, true)
        }
        return
      }
      
      // Load from http service
      self.downloader.downloadImage(
        with: url,
        cropSize: cropSize,
        priority: priority,
        completion: completion)
    }
  }
  
  @objc(cancelDownloadWithURL:)
  public func cancelDownload(with url: URL) {
    downloader.cancelDownload(with: url)
  }
}
