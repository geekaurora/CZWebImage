//
//  FeedListTableDataSource.swift
//  CZWebImageDemo
//
//  Created by Cheng Zhang on 11/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

/// DataSource for tableView of FeedList
class FeedListTableDataSource: NSObject {
    private var viewModel: FeedListViewModel
    
    init(viewModel: FeedListViewModel) {
        self.viewModel = viewModel
    }
}

extension FeedListTableDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.feeds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedListCell.cellId) as? FeedListCell else {
            fatalError("Failed to dequeue cell.")
        }
        let feed = viewModel.feeds[indexPath.row]
        cell.config(with: feed)
        return cell
    }
}
