//
//  DLSmoothTableViewSwiftVC.swift
//  DLObjectLearningProject
//
//  Created by denglong on 21/12/2017.
//  Copyright © 2017 long deng. All rights reserved.
//  tableview相关流畅度体验测试

import UIKit

class DLSmoothTableViewSwiftVC: UIViewController,UITableViewDelegate, UITableViewDataSource {

    lazy fileprivate var exampleTableView: UITableView? = {
        let exampleTableView:UITableView = UITableView()
        exampleTableView.delegate = self
        exampleTableView.dataSource = self
        self.view.addSubview(exampleTableView)
        return exampleTableView
    }()
    
    fileprivate static let IDENTIFIER = "IDENTIFIER"
    fileprivate static let CELL_HEIGHT: CGFloat = 135.0
    
//    override func loadView() {//会导致黑屏
//        view = UIView()
//        exampleTableView = UITableView()
//        exampleTableView?.delegate = self
//        exampleTableView?.dataSource = self
//        view.addSubview(exampleTableView!)
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        exampleTableView?.frame = view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        exampleTableView?.register(UITableViewCell.self, forCellReuseIdentifier: DLSmoothTableViewSwiftVC.IDENTIFIER)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DLSmoothTableViewSwiftVC.CELL_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("currentMode 当前的runloop模式：\(String(describing: RunLoop.current.currentMode))")
        
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: DLSmoothTableViewSwiftVC.IDENTIFIER)!
        cell.selectionStyle = .none
        cell.currentIndexPath = indexPath
        
        //类方法，添加耗时任务
        DLSmoothTableViewSwiftVC.task_5(cell, indexPath: indexPath)
        DWURunLoopWorkDistribution.shared().addTask({ () -> Bool in
            if cell.currentIndexPath != indexPath {//如果来到不是当前行，就没有必要添加耗时任务了
                return false
            }else{
                DLSmoothTableViewSwiftVC.task_2(cell, indexPath: indexPath)
                return true
            }
        }, withKey: indexPath)
        
        DWURunLoopWorkDistribution.shared().addTask({ () -> Bool in
            if cell.currentIndexPath != indexPath {
                return false
            } else {
                UIViewController.task_3(cell, indexPath: indexPath)
                return true
            }
        }, withKey: indexPath)
        DWURunLoopWorkDistribution.shared().addTask({ () -> Bool in
            if cell.currentIndexPath != indexPath {
                return false
            } else {
                UIViewController.task_4(cell, indexPath: indexPath)
                return true
            }
        }, withKey: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 399
    }


}
