//
//  VideoCell.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/15.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import SnapKit

class VideoCell: UITableViewCell {
    
    var playButtonCallBack: (() -> Void)?
    
    private lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "button_cover_video_play"), for: .normal)
        button.addTarget(self, action: #selector(onPlay(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var placeholderView: UIImageView = UIImageView(image: UIImage(named: "placeholder _image"))
    
    lazy var playerView: EmbedPlayerView = {
        let view = EmbedPlayerView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpUI() {
        contentView.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { (make) in
            make.edges.equalTo(contentView)
        }
        
        contentView.addSubview(playButton)
        playButton.snp.makeConstraints { (make) in
            make.center.equalTo(contentView)
            make.width.height.equalTo(30)
        }
    }
    
    @objc
    func onPlay(_ button: UIButton) {
        playButtonCallBack?()
    }
}
