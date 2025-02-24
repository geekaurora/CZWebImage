import SwiftUI
import CZWebImageAsyncAwait

class GroupFetchExampleViewState : ObservableObject {
  @Published var feeds: [Feed]? = []

  @MainActor
  func fetchImages() async {
    self.feeds = try? await withThrowingTaskGroup(of: Feed.self) { group in
      for feed in FeedMock.feeds {
        group.addTask {
          let image = try? await SwiftConcurrentFetcher.shared.fetch(url: URL(string: feed.imageUrl)!)
          var newFeed = feed.mutableCopy()
          newFeed.image = image
          return newFeed
        }
      }

      var feeds = [Feed]()
      for try await feed in group {
        print("Completed fetching! Feed.id = \(feed.id)")

        feeds.append(feed)
      }
      return feeds
    }
  }

}
