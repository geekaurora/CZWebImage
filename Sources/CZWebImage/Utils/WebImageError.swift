import UIKit
import CZUtils
import CZNetworking

/// Error class for CZWebImage
open class WebImageError: CZError {
    static let invalidData = WebImageError("Invalid image data.")
    
    public init(_ description: String? = nil, code: Int = -99) {
        super.init(domain: CZWebImageConstants.errorDomain, code: code, description: description)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
