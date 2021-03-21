import UIKit
import CZUtils
import CZNetworking
import CZWebFileDownloader

public typealias CZImageDownloderCompletion = (_ image: UIImage?, _ error: Error?, _ fromCache: Bool) -> Void

/**
 Asynchronous image downloading class on top of OperationQueue
 */
internal class CZImageDownloader: NSObject {
  private enum Constant {
    static let imageDownloadQueueName = "com.tony.image.download"
    static let imageDecodeQueueName = "com.tony.image.decode"
  }
  
  private lazy var httpFileDownloader: CZHttpFileDownloader<UIImage> = {
    let httpFileDownloader = CZHttpFileDownloader<UIImage>(
      cache: self.cache,
      downloadQueueMaxConcurrent: CZWebImageConstants.downloadQueueMaxConcurrent,
      decodeQueueMaxConcurrent: CZWebImageConstants.decodeQueueMaxConcurrent,
      errorDomain: CZWebImageConstants.errorDomain,
      shouldObserveOperations: CZWebImageConstants.shouldObserveOperations)
    return httpFileDownloader
  }()
  private let cache: CZImageCache
  
  public init(cache: CZImageCache) {
    self.cache = cache
    super.init()
  }
    
  public func downloadImage(with url: URL?,
                            cropSize: CGSize? = nil,
                            priority: Operation.QueuePriority = .normal,
                            completion: @escaping CZImageDownloderCompletion) {
    httpFileDownloader.downloadHttpFile(
      with: url,
      priority: priority,
      decodeData: { [weak self] (data: Data) -> (UIImage?, Data?)? in
        guard let `self` = self,
              let image = UIImage(data: data) else {
          return nil
        }
        let (outputImage, ouputData) = self.cropImageIfNeeded(image, data: data, cropSize: cropSize)
        return (outputImage, ouputData)
      },
      completion: completion
    )
  }
  
  @objc(cancelDownloadWithURL:)
  public func cancelDownload(with url: URL?) {
    httpFileDownloader.cancelDownload(with: url)
  }
}

// MARK: - Private methods

private extension CZImageDownloader {
  func cropImageIfNeeded(_ image: UIImage, data: Data, cropSize: CGSize?) -> (image: UIImage, data: Data?) {
    guard let cropSize = cropSize, cropSize != .zero else {
      return (image, data)
    }
    let croppedImage = image.crop(toSize: cropSize)
    return (croppedImage, croppedImage.pngData())
  }
}
