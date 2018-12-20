//
//  FeedListViewController.swift
//  CZWebImageDemo
//
//  Created by Cheng Zhang on 11/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

class FeedListViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    
    private lazy var viewModel = {
        return FeedListViewModel()
    }()
    
    private lazy var feedListTableDataSource: FeedListTableDataSource = {
        return FeedListTableDataSource(viewModel: viewModel)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = feedListTableDataSource        
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    // MARK: - Screen Rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
}

