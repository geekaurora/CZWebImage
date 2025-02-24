import SwiftUI
import CZWebImageAsyncAwait

struct GroupFetchExampleView : View {
  @ObservedObject private var state = SwiftImageState()

  var body: some View {
    List {
      ForEach(FeedMock.imageUrls, id: \.self) {
        SwiftImage($0) { imageView in
          imageView
            .resizable()
            .aspectRatio(1, contentMode: .fit)
        }
      }
    }
  }
}
