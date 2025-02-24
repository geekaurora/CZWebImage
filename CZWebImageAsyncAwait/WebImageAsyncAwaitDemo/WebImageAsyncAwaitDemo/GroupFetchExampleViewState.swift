import SwiftUI
import CZWebImageAsyncAwait

class GroupFetchExampleViewState : ObservableObject {
  @Published var feeds: [Feed]? = []

  @MainActor
  func fetchImages() async {
    self.feeds = try? await withThrowingTaskGroup(of: Feed.self) { group in
      for feed in FeedMock.feeds {
        group.addTask {
          let image = try! await SwiftConcurrentFetcher.shared.fetch(url: URL(string: feed.imageUrl)!)!
          let newFeed = Feed(id: feed.id, imageUrl: feed.imageUrl, image: image)
          return newFeed
        }
      }

      var feeds = [Feed]()

      for try await feed in group {
        feeds.append(feed)
      }

      return feeds
    }
  }

}
