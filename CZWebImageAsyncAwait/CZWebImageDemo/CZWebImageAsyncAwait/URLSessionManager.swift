import UIKit
import CZUtils

actor URLSessionManager {
  static let shared = URLSessionManager()
  
  private var memoryCache = [URL: UIImage]()
  
  public func fetch(url: URL) async throws -> UIImage? {
    if let cachedImage = memoryCache[url] {
      return cachedImage
    }    
    let (data, response) = try await URLSession.shared.data(from: url)
    let image = UIImage(data: data)
    
    memoryCache[url] = image
    return image
  }
  
}
