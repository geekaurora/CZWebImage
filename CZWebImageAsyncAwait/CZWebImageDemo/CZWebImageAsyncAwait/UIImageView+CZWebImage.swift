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
      let image = try await URLSessionManager.shared.fetch(url:url)
      self.image = image
      self.layoutIfNeeded()
    }
  }
  
}

