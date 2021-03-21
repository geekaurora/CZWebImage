import Foundation
import CZUtils
import CZNetworking

/**
 Concurrent operation class for httpFile downloading OperationQueue, supports success/failure/progress callback
 */
class HttpFileDownloadOperation: ConcurrentBlockOperation {
    
    private var requester: HTTPRequestWorker?
    private var progress: HTTPRequestWorker.Progress?
    private var success: HTTPRequestWorker.Success?
    private var failure: HTTPRequestWorker.Failure?
    let url: URL

    required init(url: URL,
                  progress: HTTPRequestWorker.Progress? = nil,
                  success: HTTPRequestWorker.Success?,
                  failure: HTTPRequestWorker.Failure?) {
        self.url = url
        self.progress = progress
        super.init()
        
        self.props["url"] = url
        self.success = { [weak self] (data, reponse) in
            // Update Operation's `isFinished` prop
            self?.finish()
            success?(data, reponse)
        }
        
        self.failure = { [weak self] (reponse, error) in
            // Update Operation's `isFinished` prop
            self?.finish()
            failure?(reponse, error)
        }
    }
    
    override func execute() {
        downloadHttpFile(url: url)
    }
    
    override func cancel() {
        super.cancel()
        requester?.cancel()
    }
    
}

private extension HttpFileDownloadOperation {
    func downloadHttpFile(url: URL) {
        requester = HTTPRequestWorker(
            .GET,
            url: url,
            params: nil,
            shouldSerializeJson: false,
            success: success,
            failure: failure,
            progress: progress)
        requester?.start()
    }
}




