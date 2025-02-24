import SwiftUI
import CZWebImageAsyncAwait

struct GroupFetchExampleView : View {
  @ObservedObject private var state = GroupFetchExampleViewState()

  var body: some View {
    VStack {
      if let feeds = state.feeds {
        List {
          ForEach(feeds, id: \.id) {
            Image(uiImage: $0.image!)
          }
        }
      }
    }
    .task {
      await state.fetchImages()
    }
  }
}
