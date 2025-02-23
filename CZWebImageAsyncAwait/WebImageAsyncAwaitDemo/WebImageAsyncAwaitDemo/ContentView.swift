import SwiftUI

struct ContentView: View {
  @State var isSingleFetchExampleViewActive = false
  @State var isGroupFetchExampleViewActive = false

  public var body: some View {
    if #available(iOS 16, *)  {
      return NavigationStack {
        VStack(alignment: .center, spacing: 20) {
          NavigationLink(
            destination: SingleFetchExampleView(),
            isActive: $isSingleFetchExampleViewActive
          ) {
            Text("SingleFetchExampleView")
          }

          NavigationLink(
            destination: GroupFetchExampleView(),
            isActive: $isGroupFetchExampleViewActive
          ) {
            Text("GroupFetchExampleView")
          }
        }
      }
    }
  }

}
