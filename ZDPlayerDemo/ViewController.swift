//
//  ViewController.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let dataSource = ["NormalPlayController", "Vertical Player", "Custom Player", "Custom Player 2", "Embed in cell of tableView"]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "索引"
        view.addSubview(tableView)
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            navigationController?.pushViewController(NormalPlayController(), animated: true)
        } else if indexPath.row == 1{
            
        } else if indexPath.row == 2 {
            
        } else if indexPath.row == 3 {
            
        } else {
            
        }
    }
}
