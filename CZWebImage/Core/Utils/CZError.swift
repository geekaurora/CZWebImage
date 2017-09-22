//
//  CZError.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

open class CZError: NSError {    
    public init(domain: String, code: Int = 99, description: String? = nil) {
        var userInfo: [AnyHashable: Any]? = nil
        if let description = description {
            userInfo = [NSLocalizedDescriptionKey: description]
        }
        super.init(domain: domain, code: code, userInfo: userInfo)
    }
    
    required public  init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
