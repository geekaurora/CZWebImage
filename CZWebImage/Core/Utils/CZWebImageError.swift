//
//  CZWebImageError.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZNetworking

open class CZWebImageError: CZError {
    public init(_ description: String? = nil, code: Int = 99) {
        super.init(domain: CZWebImageConstants.errorDomain, code: code, description: description)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
