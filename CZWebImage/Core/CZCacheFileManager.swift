//
//  CZCacheFileManager.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 9/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZUtils

internal class CZCacheFileManager: NSObject {
    static let cacheFolder: String = {
        let cacheFolder = CZFileHelper.documentDirectory + "/CZCache/"
        
        let fileManager = FileManager()
        if !fileManager.fileExists(atPath: cacheFolder) {
            do {
                try fileManager.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                assertionFailure("Failure of creating folder! Error - \(error.localizedDescription); Folder - \(cacheFolder)")
            }
        }
        return cacheFolder
    }()
}
