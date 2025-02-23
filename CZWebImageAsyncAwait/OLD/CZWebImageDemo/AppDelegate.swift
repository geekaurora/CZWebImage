//
//  AppDelegate.swift
//  CZWebImageDemo
//
//  Created by Cheng Zhang on 11/22/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//
import UIKit

/*
 - MVVM
     - M
         - Feed
             - id
             - imageUrl
     - V
         - ListView (TableView)
         - CellView
     - VM
         - ListViewModel
         - CellViewModel
         - FeedListTableDataSource
     - Controller
         - container
*/

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}



