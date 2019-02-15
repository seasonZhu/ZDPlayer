//
//  EmbedTableViewController.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/15.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import ZDPlayer
import SnapKit

class EmbedTableViewController: UITableViewController {
    
    
    var player: ZDPlayer!
    var playerView: EmbedPlayerView!
    var currentPlayIndexPath : IndexPath?
    var smallScreenView : UIView!
    var panGesture: UIPanGestureRecognizer!
    var playerViewSize : CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(describing: type(of: self))
        tableView.register(VideoCell.self, forCellReuseIdentifier: "reuseIdentifier")
        tableView.rowHeight = 233
        setUpSmallScreenView()
        addTableViewObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        smallScreenView?.removeFromSuperview()
        playerView?.removeFromSuperview()
        player?.clearPlayer()
        currentPlayIndexPath = nil
    }
    
    deinit {
        print(String(describing: type(of: self)) + "销毁了")
        player?.clearPlayer()
        removeTableViewObserver()
    }
    
    func setUpSmallScreenView() {
        smallScreenView = UIView()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
        //smallScreenView.addGestureRecognizer(panGesture)
    }
    
    @objc
    func onPanGesture(_ gesture: UIPanGestureRecognizer) {
        
        let screenBounds = UIScreen.main.bounds
        
        var point = gesture.location(in: UIApplication.shared.keyWindow)
        if let gestureView = gesture.view {
            let width = gestureView.frame.width
            let height = gestureView.frame.height
            let distance = CGFloat(10.0)
            
            if gesture.state == .ended {
                if point.x < width/2 {
                    point.x = width/2 + distance
                } else if point.x > screenBounds.width - width/2 {
                    point.x = screenBounds.width - width/2 - distance
                }
                
                if point.y < height/2 + 64.0 {
                    point.y = height/2 + distance + 64.0
                } else if point.y > screenBounds.height - height/2 {
                    point.y = screenBounds.height - height/2 - distance
                }
                UIView.animate(withDuration: 0.5, animations: {
                    gestureView.center = point
                })
            } else {
                gestureView.center = point
            }
        }
    }
    
    func startPlayer(cell: VideoCell, indexPath: IndexPath) {
        if player != nil {
            player.clearPlayer()
        }
        
        playerView = EmbedPlayerView()
        player = ZDPlayer(playerView: playerView)
        player.backgroundMode = .suspend
        
        cell.contentView.addSubview(player.playerView)
        player.playerView.snp.makeConstraints { (make) in
            make.edges.equalTo(cell)
        }
        
        if indexPath.row % 2 == 0  {
            player.loadVideo(url: URL(fileURLWithPath: Bundle.main.path(forResource: "2", ofType: "mp4")!))
        }else {
            player.loadVideo(url: URL(string:"http://lxdqncdn.miaopai.com/stream/6IqHc-OnSMBIt-LQjPJjmA__.mp4?ssig=a81b90fdeca58e8ea15c892a49bce53f&time_stamp=1508166491488")!)
        }
        
        player.play()
    }
    
    func addSmallScreenView() {
        player.playerView.removeFromSuperview()
        smallScreenView.removeFromSuperview()
        playerView.isSmallMode = true
        
        UIApplication.shared.keyWindow?.addSubview(smallScreenView)
        
        let smallScreenWidth = (playerViewSize?.width)! / 2
        let smallScreenHeight = (playerViewSize?.height)! / 2
        smallScreenView.snp.remakeConstraints { (make) in
            make.bottom.equalTo(self.tableView.snp.bottom).offset(-10)
            make.right.equalTo(self.tableView.snp.right).offset(-10)
            make.width.equalTo(smallScreenWidth)
            make.height.equalTo(smallScreenHeight)
        }
        smallScreenView.addSubview(player.playerView)
        player.playerView.snp.remakeConstraints { (make) in
            make.edges.equalTo(smallScreenView)
        }
    }
    

}

extension EmbedTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! VideoCell
        playerViewSize = cell.contentView.bounds.size
        cell.playButtonCallBack = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.currentPlayIndexPath = indexPath
            strongSelf.startPlayer(cell: cell, indexPath: indexPath)
        }
        
        return cell
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("scrollViewDidEndDragging, decelerate:\(decelerate)")
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("scrollViewDidEndDecelerating")
        tableViewStopScrollingAndPlayVideoWhichTheCellInMiddle(scrollView: scrollView)
    }
}

extension EmbedTableViewController {
    /// tableView停止滑动,其居中的cell播放视频内容
    private func tableViewStopScrollingAndPlayVideoWhichTheCellInMiddle(scrollView: UIScrollView) {
        guard let tableView = scrollView as? UITableView else {
            return
        }
        
        guard let cells = tableView.visibleCells as? [VideoCell] else {
            return
        }
        
        let middleCells = cells.filter { (cell) -> Bool in
            guard let indexPath = tableView.indexPath(for: cell) else {
                return false
            }
            let cellInTableView = tableView.rectForRow(at: indexPath)
            let rect = tableView.convert(cellInTableView, to: tableView.superview)
            return rect.contains(view.center)
        }
        
        if let firstCell = middleCells.first {
            currentPlayIndexPath = tableView.indexPath(for: firstCell)
            guard let indexPath = currentPlayIndexPath else {
                return
            }
            startPlayer(cell: firstCell, indexPath: indexPath)
        }
    }
}

extension EmbedTableViewController {
    func addTableViewObserver() {
        let options = NSKeyValueObservingOptions([.new, .initial])
        tableView?.addObserver(self, forKeyPath: #keyPath(UITableView.contentOffset), options: options, context: nil)
    }
    
    func removeTableViewObserver() {
        tableView?.removeObserver(self, forKeyPath: #keyPath(UITableView.contentOffset))
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(UITableView.contentOffset) {
            if let playIndexPath = currentPlayIndexPath {
                
                if let cell = tableView.cellForRow(at: playIndexPath) {
                    if player.playerView.isFullScreen { return }
                    let visibleCells = tableView.visibleCells
                    if visibleCells.contains(cell) {
                        smallScreenView.removeFromSuperview()
                        cell.contentView.addSubview(player.playerView)
                        player.playerView.snp.remakeConstraints { (make) in
                            make.edges.equalTo(cell)
                        }
                        playerView.isSmallMode = false
                    } else {
                        addSmallScreenView()
                    }
                } else {
                    if isViewLoaded && (view.window != nil) {
                        if smallScreenView.superview != UIApplication.shared.keyWindow {
                            addSmallScreenView()
                        }
                    }
                }
            }
        }
    }
}
