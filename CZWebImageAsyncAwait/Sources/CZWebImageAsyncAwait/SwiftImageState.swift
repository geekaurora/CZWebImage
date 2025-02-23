import SwiftUI
// import CZWebImage

public class SwiftImageState: ObservableObject {

  @Published var image: UIImage?
  
  private var url: URL?
  
  /// Fetches image data with `url` and triggers ui reload on completion.
  @MainActor
  public func download(url: URL) async {
    self.url = url
    
    self.image = try? await SwiftConcurrentFetcher.shared.fetch(url: url)

//      .downloadImage(with: url) { (image, error, fromCache) in
//      // Verify download imageUrl matches the original one.
//      guard self.url == url else { return }
//      self.image = image
//    }
  }
}
