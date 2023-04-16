import Foundation
import CZUtils

actor URLSessionManager {
  static let shared = URLSessionManager()
  
  private var memoryCache = [URL: Data]()
  
  public func fetch(url: URL) async throws -> Data? {
    let (data, response) = try await URLSession.shared.data(from: url)
    memoryCache[url] = data
    return data
  }
  
}
