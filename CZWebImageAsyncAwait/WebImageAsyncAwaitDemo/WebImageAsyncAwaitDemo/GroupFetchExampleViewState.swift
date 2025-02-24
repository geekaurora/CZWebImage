import SwiftUI
import CZWebImageAsyncAwait

class GroupFetchExampleViewState : ObservableObject {
  @Published var images: [UIImage]? = []

  func fetchImages() async {
    self.images = try? await withThrowingTaskGroup(of: UIImage.self) { group in
      for imageUrl in FeedMock.imageUrls {
        group.addTask {
          return try! await SwiftConcurrentFetcher.shared.fetch(url: URL(string: imageUrl)!)!
        }
      }

      var images = [UIImage]()

      for try await image in group {
        images.append(image)
      }

      return images
    }
  }

}
