//
//  CZHTTPCache.swift
//  CZNetworking
//
//  Created by Cheng Zhang on 9/7/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CommonCrypto

/**
 *  HTTPCache for GET response
 */
open class CZHTTPCache: NSObject {
    fileprivate var ioQueue: DispatchQueue

    override init() {
        ioQueue = DispatchQueue(label: "com.tony.httpCache.ioQueue",
                                qos: .default,
                                attributes: .concurrent,
                                autoreleaseFrequency: .inherit,
                                target: nil)
        super.init()
    }

    fileprivate let folder: URL = {
        var documentPath = try! FileManager.default.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let cacheFolder = documentPath.appendingPathComponent("CZHTTPCache")
        do {
            try FileManager.default.createDirectory(atPath: cacheFolder.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            assertionFailure("Failed to create HTTPCache folder. Error: \(error)")
        }
        return cacheFolder
    }()
    static func cacheKey(url: URL, parameters: [AnyHashable: Any]?) -> String {
        return CZHTTPJsonSerializer.url(url, append: parameters).absoluteString
    }

    func saveData<T>(_ data: T, forKey key: String) {
        ioQueue.async(flags: .barrier) {[weak self] in
            guard let `self` = self else {return}
            switch data {
            case let data as NSDictionary:
                let success = data.write(to: self.fileURL(forKey: key), atomically: false)
                return
            default:
                return
            }
        }
    }
    
    func readData(forKey key: String) -> Any? {
        return ioQueue.sync {[weak self] () -> Any? in
            guard let `self` = self else {return nil}
            if let dict = NSDictionary(contentsOf: self.fileURL(forKey: key)) {
                return dict
            }
            if let array = NSArray(contentsOf: self.fileURL(forKey: key)) {
                return array
            }
            return nil

        }
    }
}

fileprivate extension CZHTTPCache {
    func fileURL(forKey key: String) -> URL {
        // If use path make sure add "file://" accordingly
        return folder.appendingPathComponent(key.MD5)
    }

}

protocol FileWritable {
    func write(toFile: String, atomically: Bool) -> Bool
}

extension String {
    /// MD5 HashValue: Should #import <CommonCrypto/CommonCrypto.h> in your Bridging-Header file
    var MD5: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)

        if let d = self.data(using: String.Encoding.utf8) {
            _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
                CC_MD5(body, CC_LONG(d.count), &digest)
            }
        }

        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
}



