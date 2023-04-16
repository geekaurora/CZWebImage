//
//  FeedListCell.swift
//  CZWebImageDemo
//
//  Created by Cheng Zhang on 11/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
// import CZWebImage

class FeedListCell: UITableViewCell {
    static let cellId = "FeedListCell"
    
    @IBOutlet var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var feedImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func config(with feed: Feed) {
        feedImageView.image = nil
        
        if let imageUrlStr = feed.imageUrl,
           let imageUrl = URL(string: imageUrlStr) {
            // set `imageUrl`for `imageView`
            // download image asynchronously in background thread
            feedImageView.cz_setImage(with: imageUrl)
        }
        imageViewWidthConstraint.constant = UIScreen.currWidth
    }    
}
