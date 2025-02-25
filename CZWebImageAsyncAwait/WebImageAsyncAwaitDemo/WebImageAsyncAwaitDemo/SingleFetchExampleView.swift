import SwiftUI
import CZWebImageAsyncAwait

struct SingleFetchExampleView : View {
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
