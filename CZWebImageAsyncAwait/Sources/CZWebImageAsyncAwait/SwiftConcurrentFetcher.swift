import UIKit
// import CZUtils

actor SwiftConcurrentFetcher {
  static let shared = SwiftConcurrentFetcher()

  private var memoryCache = [URL: UIImage]()
  
  public func fetch(url: URL) async throws -> UIImage? {
    if let cachedImage = memoryCache[url] {
      return cachedImage
    }
    // Fetch from network.
    let (data, response) = try await URLSession.shared.data(from: url)
    let image = UIImage(data: data)
    
    // Cache the image.
    memoryCache[url] = image
    return image
  }
}
