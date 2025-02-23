import SwiftUI

public struct SwiftImage<V: View>: View {
  @ObservedObject private var state = SwiftImageState()

  public typealias Config<V> = (Image) -> V

  private let placeholder: UIImage
  private let url: URL?
  private let config: Config<V>?

  /// Initializer of SwiftImage view with specified params.
  ///
  /// - Parameters:
  ///   - url: The string to download the image.
  ///   - placeholder: The placeholder image.
  ///   - config: Closure be used to config SwiftImage view.
  public init(_ url: URL?,
              placeholder: UIImage = UIImage(),
              config: Config<V>? = nil) {
    assert(url != nil)

    self.placeholder = placeholder
    self.config = config
    self.url = url
  }

  /// Convenience initializer of SwiftImage view with specified params.
  ///
  /// - Parameters:
  ///   - urlString: The url string to download the image.
  ///   - placeholder: The placeholder image.
  ///   - config: Closure be used to config SwiftImage view.
  public init(_ urlString: String?,
              placeholder: UIImage = UIImage(),
              config: Config<V>? = nil) {
    let url = (urlString == nil) ? nil : URL(string: urlString!)
    self.init(url, placeholder: placeholder, config: config)
  }

  public var body: some View {
    contentView()
      .task {
        if let url {
          await self.state.download(url: url)
        }
      }
  }

  @ViewBuilder
  public func contentView() -> some View {
    let image: UIImage = state.image ?? placeholder
    let imageView = Image(uiImage: image)
    if let config = config {
      config(imageView)
    }
    imageView
  }
}
