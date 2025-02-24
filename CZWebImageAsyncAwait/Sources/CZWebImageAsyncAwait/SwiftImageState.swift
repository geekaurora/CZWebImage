import SwiftUI

public class SwiftImageState: ObservableObject {
  @Published var image: UIImage?

  public init() {}

  /// Fetches image data with `url` and triggers ui reload on completion.
  @MainActor
  public func download(url: URL) async {
    self.image = try? await SwiftConcurrentFetcher.shared.fetch(url: url)
  }
}
