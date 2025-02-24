import SwiftUI
import CZWebImageAsyncAwait

struct GroupFetchExampleView : View {
  @ObservedObject private var state = GroupFetchExampleViewState()

  var body: some View {
    VStack {
      if let images = state.images {
        List {
          ForEach(images, id: \.self) {
            Image(uiImage: $0)
          }
        }
      }
    }
    .task {
      await state.fetchImages()
    }
  }
}
