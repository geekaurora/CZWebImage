//
//  FeedsMocker.swift
//  CZWebImageDemo
//
//  Created by Cheng Zhang on 11/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

typealias FeedDictionary = [String: Any]

class FeedsMocker: NSObject {
    static let shared = FeedsMocker()
    
    fileprivate(set) lazy var feeds: [Feed] = {
        let path = Bundle.main.path(forResource: "feeds", ofType: "json")!
        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
            guard let feedDicts = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [FeedDictionary] else {
                preconditionFailure()
            }
            return feedDicts.flatMap{ Feed(dictionary: $0)}
        } catch {
            fatalError("Failed to deserialize feeds with JSON file. Error: \(error.localizedDescription)")
        }
    }()
}
