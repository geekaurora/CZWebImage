import UIKit
import CZUtils
import CZNetworking

/// Error class for CZWebHttpFile
open class WebHttpFileError: CZError {
    static let invalidData = WebHttpFileError("Invalid httpFile data.")
    
    public init(_ description: String? = nil, code: Int = -99) {
        super.init(domain: CZHttpFileDownloaderConstant.errorDomain, code: code, description: description)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
