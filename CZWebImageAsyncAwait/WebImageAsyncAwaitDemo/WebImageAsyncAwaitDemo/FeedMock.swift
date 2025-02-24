import SwiftUI
import CZWebImageAsyncAwait

class FeedMock {
  static let imageUrls = [
    "https://raw.githubusercontent.com/geekaurora/resources/main/images/01bff78eae0870a01ed491ef86405bdf.jpg",
    "https://raw.githubusercontent.com/geekaurora/resources/main/images/14729eb660b3a409368f820a053ac319.jpg",
    "https://raw.githubusercontent.com/geekaurora/resources/main/images/16c9316d8f5dbccf394f20361c96a541.jpg",
    "https://raw.githubusercontent.com/geekaurora/resources/main/images/297ee57338cb757d5bf359f5f0dd666f.jpg",
    "https://raw.githubusercontent.com/geekaurora/resources/main/images/3a7635518ee11c02c113c6cb88f1613e.jpg",
  ]

  static let feeds: [Feed] = [
    .init(id: 0, imageUrl: "https://raw.githubusercontent.com/geekaurora/resources/main/images/01bff78eae0870a01ed491ef86405bdf.jpg"),
    .init(id: 1, imageUrl: "https://raw.githubusercontent.com/geekaurora/resources/main/images/14729eb660b3a409368f820a053ac319.jpg"),
    .init(id: 2, imageUrl: "https://raw.githubusercontent.com/geekaurora/resources/main/images/16c9316d8f5dbccf394f20361c96a541.jpg"),
    .init(id: 3, imageUrl: "https://raw.githubusercontent.com/geekaurora/resources/main/images/297ee57338cb757d5bf359f5f0dd666f.jpg"),
    .init(id: 4, imageUrl: "https://raw.githubusercontent.com/geekaurora/resources/main/images/3a7635518ee11c02c113c6cb88f1613e.jpg"),
  ]
}

struct Feed {
  let id: Int
  let imageUrl: String
  var image: UIImage?

  init(id: Int, imageUrl: String, image: UIImage? = nil) {
    self.id = id
    self.imageUrl = imageUrl
    self.image = image
  }

  func mutableCopy() -> Feed {
    Feed(id: id, imageUrl: imageUrl, image: image)
  }
}
