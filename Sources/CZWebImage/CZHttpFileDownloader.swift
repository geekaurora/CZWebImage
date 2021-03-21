import UIKit
import CZUtils
import CZNetworking
import CZHttpFileCache

public enum CZHttpFileDownloaderConstant {
  public static var shouldObserveOperations = false
  public static var downloadQueueMaxConcurrent = 5
  public static var decodeQueueMaxConcurrent = downloadQueueMaxConcurrent
  public static var errorDomain = "CZHttpFileDownloader"
}

private var kvoContext: UInt8 = 0

/**
 Asynchronous image downloading class on top of OperationQueue
 */
public class CZHttpFileDownloader: NSObject {
  public static let shared = CZHttpFileDownloader()
  private let imageDownloadQueue: OperationQueue
  private let imageDecodeQueue: OperationQueue
  public enum Constant {
    public static let imageDownloadQueueName = "com.cz.httpfile.download"
    public static let imageDecodeQueueName = "com.cz.httpfile.decode"
    public static var kOperations = "operations"
  }
  private let shouldObserveOperations: Bool
  
  public init(downloadQueueMaxConcurrent: Int = CZHttpFileDownloaderConstant.downloadQueueMaxConcurrent,
              decodeQueueMaxConcurrent: Int = CZHttpFileDownloaderConstant.decodeQueueMaxConcurrent,
              errorDomain: String = CZHttpFileDownloaderConstant.errorDomain,
              shouldObserveOperations: Bool = CZHttpFileDownloaderConstant.shouldObserveOperations,
              imageDownloadQueueName: String = Constant.imageDownloadQueueName,
              imageDecodeQueueName: String = Constant.imageDecodeQueueName) {
    self.shouldObserveOperations = shouldObserveOperations
    
    imageDownloadQueue = OperationQueue()
    imageDownloadQueue.name = imageDownloadQueueName
    imageDownloadQueue.qualityOfService = .userInteractive
    imageDownloadQueue.maxConcurrentOperationCount = downloadQueueMaxConcurrent
    
    imageDecodeQueue = OperationQueue()
    imageDownloadQueue.name = imageDecodeQueueName
    imageDecodeQueue.maxConcurrentOperationCount = decodeQueueMaxConcurrent
    super.init()
    
    if shouldObserveOperations {
      imageDownloadQueue.addObserver(self, forKeyPath: Constant.kOperations, options: [.new, .old], context: &kvoContext)
    }
  }
  
  deinit {
    if shouldObserveOperations {
      imageDownloadQueue.removeObserver(self, forKeyPath: Constant.kOperations)
    }
    imageDownloadQueue.cancelAllOperations()
  }
  
  public func downloadImage(with url: URL?,
                            cropSize: CGSize? = nil,
                            priority: Operation.QueuePriority = .normal,
                            completion: @escaping (_ image: UIImage?, _ error: Error?, _ fromCache: Bool) -> Void) {
    guard let url = url else { return }
    cancelDownload(with: url)
    
    let operation = ImageDownloadOperation(url: url,
                                           progress: nil,
                                           success: { [weak self] (task, data) in
                                            guard let `self` = self, let data = data else {
                                              completion(nil, WebImageError.invalidData, false)
                                              return
                                            }
                                            // Decode/crop image in decode OperationQueue
                                            self.imageDecodeQueue.addOperation {
                                              guard let image = UIImage(data: data) else {
                                                completion(nil, WebImageError.invalidData, false)
                                                return
                                              }
                                              let (outputImage, ouputData) = self.cropImageIfNeeded(image, data: data, cropSize: cropSize)
                                              CZImageCache.shared.setCacheFile(withUrl: url, data: ouputData)
                                              
                                              // Call completion on mainQueue
                                              MainQueueScheduler.async {
                                                completion(outputImage, nil, false)
                                              }
                                            }
                                           }, failure: { (task, error) in
                                            completion(nil, error, false)
                                           })
    operation.queuePriority = priority
    imageDownloadQueue.addOperation(operation)
  }
  
  @objc(cancelDownloadWithURL:)
  public func cancelDownload(with url: URL?) {
    guard let url = url else { return }
    
    let cancelIfNeeded = { (operation: Operation) in
      if let operation = operation as? ImageDownloadOperation,
         operation.url == url {
        operation.cancel()
      }
    }
    imageDownloadQueue.operations.forEach(cancelIfNeeded)
  }
}

// MARK: - Private methods

private extension CZHttpFileDownloader {
  
  func cropImageIfNeeded(_ image: UIImage, data: Data, cropSize: CGSize?) -> (image: UIImage, data: Data?) {
    guard let cropSize = cropSize, cropSize != .zero else {
      return (image, data)
    }
    let croppedImage = image.crop(toSize: cropSize)
    return (croppedImage, croppedImage.pngData())
  }
  
}

// MARK: - KVO Delegation

extension CZHttpFileDownloader {
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard context == &kvoContext,
          let object = object as? OperationQueue,
          let keyPath = keyPath,
          keyPath == Constant.kOperations else {
      return
    }
    if object === imageDownloadQueue {
      CZUtils.dbgPrint("[CZHttpFileDownloader] Queued tasks: \(object.operationCount)")
    }
  }
}
