//
//  ImageGalleryViewCell.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit

class ImageGalleryViewCell: UICollectionViewCell {
    
    lazy var imageView = UIImageView()
    var selectedView: UIView?
    private var videoInfoView: VideoInfoView
    
    private let videoInfoBarHeight: CGFloat = 15
    var duration: TimeInterval? {
        didSet {
            if let duration = duration, duration > 0 {
                self.videoInfoView.duration = duration
                self.videoInfoView.isHidden = false
            } else {
                self.videoInfoView.isHidden = true
            }
        }
    }
    
    override init(frame: CGRect) {
        let videoBarFrame = CGRect(x: 0, y: frame.height - self.videoInfoBarHeight,
                                   width: frame.width, height: self.videoInfoBarHeight)
        videoInfoView = VideoInfoView(frame: videoBarFrame)
        super.init(frame: frame)
        
        for view in [imageView, videoInfoView] as [UIView] {
            view.contentMode = .scaleAspectFill
            view.translatesAutoresizingMaskIntoConstraints = false
            view.clipsToBounds = true
            contentView.addSubview(view)
        }
        
        isAccessibilityElement = true
        accessibilityLabel = "Photo"
        
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ImageConfiguration
    
    func configureCell(_ image: UIImage) {
        imageView.image = image
    }
    
    func setupConstraints() {
        
        for attribute: NSLayoutConstraint.Attribute in [.width, .height, .centerX, .centerY] {
            addConstraint(NSLayoutConstraint(item: imageView, attribute: attribute,
                                             relatedBy: .equal, toItem: self, attribute: attribute,
                                             multiplier: 1, constant: 0))
        }
    }

    func addSelectedView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        for attribute: NSLayoutConstraint.Attribute in [.width, .height, .centerX, .centerY] {
            addConstraint(NSLayoutConstraint(item: view, attribute: attribute,
                                             relatedBy: .equal, toItem: self, attribute: attribute,
                                             multiplier: 1, constant: 0))
        }
        selectedView = view
    }
}

extension ImageGalleryViewCell {
    
}

