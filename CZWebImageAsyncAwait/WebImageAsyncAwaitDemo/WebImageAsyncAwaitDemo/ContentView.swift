import SwiftUI

struct ContentView: View {
  @State 
  var isSingleFetchExampleViewActive = false

  public var body: some View {
    if #available(iOS 16, *)  {
      return NavigationStack {
        NavigationLink(
          destination: SingleFetchExampleView(),
          isActive: $isSingleFetchExampleViewActive
        ) {
          Text("SingleFetchExampleView")
        }
      }
    }
  }

}
