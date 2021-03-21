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

public enum Constant {
  public static let httpFileDownloadQueueName = "com.cz.httpfile.download"
  public static let httpFileDecodeQueueName = "com.cz.httpfile.decode"
  public static var kOperations = "operations"
}

private var kvoContext: UInt8 = 0

/**
 Asynchronous httpFile downloading class on top of OperationQueue
 */
internal class CZHttpFileDownloader<DataType: NSObjectProtocol>: NSObject {
  private let httpFileDownloadQueue: OperationQueue
  private let httpFileDecodeQueue: OperationQueue
  private let shouldObserveOperations: Bool
  private let cache: CZBaseHttpFileCache<DataType>
  
  public init(cache: CZBaseHttpFileCache<DataType>,
              downloadQueueMaxConcurrent: Int = CZHttpFileDownloaderConstant.downloadQueueMaxConcurrent,
              decodeQueueMaxConcurrent: Int = CZHttpFileDownloaderConstant.decodeQueueMaxConcurrent,
              errorDomain: String = CZHttpFileDownloaderConstant.errorDomain,
              shouldObserveOperations: Bool = CZHttpFileDownloaderConstant.shouldObserveOperations,
              httpFileDownloadQueueName: String = Constant.httpFileDownloadQueueName,
              httpFileDecodeQueueName: String = Constant.httpFileDecodeQueueName) {
    self.cache = cache
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
  
  /// Download the http file with the desired params.
  ///
  /// - Parameters:
  ///   - decodeData: Closure used to decode `Data` to tuple (DataType?, Data?). If is nil, then returns `Data` directly.
  public func downloadHttpFile(with url: URL?,
                               priority: Operation.QueuePriority = .normal,
                               decodeData: ((Data) -> (DataType?, Data?)?)?,
                               completion: @escaping (_ httpFile: DataType?, _ error: Error?, _ fromCache: Bool) -> Void) {
    guard let url = url else { return }
    cancelDownload(with: url)
    
    let operation = HttpFileDownloadOperation(
      url: url,
      progress: nil,
      success: { [weak self] (task, data) in
        guard let `self` = self, let data = data else {
          completion(nil, WebHttpFileError.invalidData, false)
          return
        }
        // Decode/crop httpFile in decode OperationQueue
        self.httpFileDecodeQueue.addOperation {
          guard let (outputHttpFile, ouputData) = (decodeData?(data)).assertIfNil else {
            completion(nil, WebHttpFileError.invalidData, false)
            return
          }
          // let (outputHttpFile, ouputData) = self.cropHttpFileIfNeeded(httpFile, data: data, cropSize: cropSize)
          
          // Save downloaded file to cache.
          self.cache.setCacheFile(withUrl: url, data: ouputData)
          // CZImageCache.shared.setCacheFile(withUrl: url, data: ouputData)
          
          // Call completion on mainQueue
          MainQueueScheduler.async {
            completion(outputHttpFile, nil, false)
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
      if let operation = operation as? HttpFileDownloadOperation,
         operation.url == url {
        operation.cancel()
      }
    }
    httpFileDownloadQueue.operations.forEach(cancelIfNeeded)
  }
  
  // MARK: - KVO Delegation
  
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
