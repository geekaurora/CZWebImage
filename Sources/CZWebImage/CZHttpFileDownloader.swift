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
 Asynchronous httpFile downloading class on top of OperationQueue
 */
public class CZHttpFileDownloader: NSObject {
  public static let shared = CZHttpFileDownloader()
  private let httpFileDownloadQueue: OperationQueue
  private let httpFileDecodeQueue: OperationQueue
  public enum Constant {
    public static let httpFileDownloadQueueName = "com.cz.httpfile.download"
    public static let httpFileDecodeQueueName = "com.cz.httpfile.decode"
    public static var kOperations = "operations"
  }
  private let shouldObserveOperations: Bool
  
  public init(downloadQueueMaxConcurrent: Int = CZHttpFileDownloaderConstant.downloadQueueMaxConcurrent,
              decodeQueueMaxConcurrent: Int = CZHttpFileDownloaderConstant.decodeQueueMaxConcurrent,
              errorDomain: String = CZHttpFileDownloaderConstant.errorDomain,
              shouldObserveOperations: Bool = CZHttpFileDownloaderConstant.shouldObserveOperations,
              httpFileDownloadQueueName: String = Constant.httpFileDownloadQueueName,
              httpFileDecodeQueueName: String = Constant.httpFileDecodeQueueName) {
    self.shouldObserveOperations = shouldObserveOperations
    
    httpFileDownloadQueue = OperationQueue()
    httpFileDownloadQueue.name = httpFileDownloadQueueName
    httpFileDownloadQueue.qualityOfService = .userInteractive
    httpFileDownloadQueue.maxConcurrentOperationCount = downloadQueueMaxConcurrent
    
    httpFileDecodeQueue = OperationQueue()
    httpFileDownloadQueue.name = httpFileDecodeQueueName
    httpFileDecodeQueue.maxConcurrentOperationCount = decodeQueueMaxConcurrent
    super.init()
    
    if shouldObserveOperations {
      httpFileDownloadQueue.addObserver(self, forKeyPath: Constant.kOperations, options: [.new, .old], context: &kvoContext)
    }
  }
  
  deinit {
    if shouldObserveOperations {
      httpFileDownloadQueue.removeObserver(self, forKeyPath: Constant.kOperations)
    }
    httpFileDownloadQueue.cancelAllOperations()
  }
  
  public func downloadImage(with url: URL?,
                            cropSize: CGSize? = nil,
                            priority: Operation.QueuePriority = .normal,
                            completion: @escaping (_ httpFile: UIImage?, _ error: Error?, _ fromCache: Bool) -> Void) {
    guard let url = url else { return }
    cancelDownload(with: url)
    
    let operation = ImageDownloadOperation(url: url,
                                           progress: nil,
                                           success: { [weak self] (task, data) in
                                            guard let `self` = self, let data = data else {
                                              completion(nil, WebImageError.invalidData, false)
                                              return
                                            }
                                            // Decode/crop httpFile in decode OperationQueue
                                            self.httpFileDecodeQueue.addOperation {
                                              guard let httpFile = UIImage(data: data) else {
                                                completion(nil, WebImageError.invalidData, false)
                                                return
                                              }
                                              let (outputImage, ouputData) = self.cropImageIfNeeded(httpFile, data: data, cropSize: cropSize)
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
    httpFileDownloadQueue.addOperation(operation)
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
    httpFileDownloadQueue.operations.forEach(cancelIfNeeded)
  }
}

// MARK: - Private methods

private extension CZHttpFileDownloader {
  
  func cropImageIfNeeded(_ httpFile: UIImage, data: Data, cropSize: CGSize?) -> (httpFile: UIImage, data: Data?) {
    guard let cropSize = cropSize, cropSize != .zero else {
      return (httpFile, data)
    }
    let croppedImage = httpFile.crop(toSize: cropSize)
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
    if object === httpFileDownloadQueue {
      CZUtils.dbgPrint("[CZHttpFileDownloader] Queued tasks: \(object.operationCount)")
    }
  }
}
