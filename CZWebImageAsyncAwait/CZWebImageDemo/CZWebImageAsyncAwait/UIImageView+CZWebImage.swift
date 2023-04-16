import UIKit
import CZUtils
import CZNetworking

public typealias CZWebImageCompletion = (UIImage?, Error?) -> Void

private var kImageUrl: UInt8 = 0

/**
 Convenient UIImageView extension for asynchronous image downloading
 */
extension UIImageView {
  public var czImageUrl: URL? {
    get { return objc_getAssociatedObject(self, &kImageUrl) as? URL }
    set { objc_setAssociatedObject(self, &kImageUrl, newValue, .OBJC_ASSOCIATION_RETAIN) }
  }
  
  @MainActor
  public func cz_setImage(with url: URL?,
                          placeholderImage: UIImage? = nil,
                          completion: CZWebImageCompletion? = nil) {
    czImageUrl = url
    image = placeholderImage
    guard let url = url else { fatalError() }
    
    Task {
      let image = try! await URLSessionManager.shared.fetch(url:)
      // self.image = image
      self.layoutIfNeeded()           
    }
    
    //        let priority: Operation.QueuePriority = options.contains(.highPriority) ? .veryHigh : .normal
    //        CZWebImageManager.shared.downloadImage(with: url, cropSize: cropSize, priority: priority) { [weak self] (image, error, fromCache) in
    //            guard let `self` = self, self.czImageUrl == url else { return }
    //
    //            if let error = error {
    //                let isCancelled = (error.retrievedCode == NSURLErrorCancelled)
    //                if !isCancelled {
    //                    assertionFailure("Failed to download image: \(url). Error - \(error.localizedDescription)")
    //                }
    //                return
    //            }
    //
    //
    //            MainQueueScheduler.sync {
    //                if !fromCache && options.contains(.fadeInAnimation) {
    //                    self.fadeIn()
    //                }
    //                self.image = image
    //                self.layoutIfNeeded()
    //                completion?(image, error)
    //            }
    //        }
  }
  
}

