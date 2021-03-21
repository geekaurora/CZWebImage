//
//  CZImageDownloader.swift
//  CZWebImage
//
//  Created by Cheng Zhang on 1/20/16.
//  Copyright © 2016 Cheng Zhang. All rights reserved.
//

import UIKit
import CZUtils
import CZNetworking
import CZHttpFileCache

public typealias CZImageDownloderCompletion = (_ image: UIImage?, _ error: Error?, _ fromCache: Bool) -> Void

/**
 Asynchronous image downloading class on top of OperationQueue
 */
public class CZImageDownloader: NSObject {
  public static let shared = CZImageDownloader()
  private enum Constant {
    static let imageDownloadQueueName = "com.tony.image.download"
    static let imageDecodeQueueName = "com.tony.image.decode"
  }
  private lazy var httpFileDownloader: CZHttpFileDownloader = {
    let httpFileDownloader = CZHttpFileDownloader()
    return httpFileDownloader
  }()
  
  public override init() {
    
    super.init()
  }
  
  
  public func downloadImage(with url: URL?,
                            cropSize: CGSize? = nil,
                            priority: Operation.QueuePriority = .normal,
                            completion: @escaping CZImageDownloderCompletion) {
    guard let url = url else { return }
    cancelDownload(with: url)
    
  }
  
  @objc(cancelDownloadWithURL:)
  public func cancelDownload(with url: URL?) {
    guard let url = url else { return }
    
  }
}

// MARK: - Private methods

private extension CZImageDownloader {
  
  func cropImageIfNeeded(_ image: UIImage, data: Data, cropSize: CGSize?) -> (image: UIImage, data: Data?) {
    guard let cropSize = cropSize, cropSize != .zero else {
      return (image, data)
    }
    let croppedImage = image.crop(toSize: cropSize)
    return (croppedImage, croppedImage.pngData())
  }
  
}
