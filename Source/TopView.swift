//
//  TopView.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit

protocol TopViewDelegate: AnyObject {
    
    func flashButtonDidPress(_ title: String)
    func rotateDeviceDidPress()
}

open class TopView: UIView {
    
    struct Dimensions {
        static let leftOffset: CGFloat = 2
        static let rightOffset: CGFloat = -7
        static let height: CGFloat = 44
    }
    
    var configuration = ImagePickerConfiguration()
    
    var currentFlashIndex = 0
    let flashButtonTitles = ["boltAuto", "boltOn", "boltOff"]
    
    open lazy var flashButton: UIButton = { [unowned self] in
        let button = UIButton()
        button.setImage(AssetManager.getImage(flashButtonTitles[0]), for: UIControl.State())
        button.addTarget(self, action: #selector(flashButtonDidPress(_:)), for: .touchUpInside)
        button.accessibilityLabel = "Flash mode is auto"
        button.accessibilityHint = "Double-tap to change flash mode"
        
        return button
    }()
    
    open lazy var rotateCamera: UIButton = { [unowned self] in
        let button = UIButton()
        button.accessibilityLabel = ""
        button.accessibilityHint = "Double-tap to rotate camera"
        button.setImage(AssetManager.getImage("cameraIcon"), for: UIControl.State())
        button.addTarget(self, action: #selector(rotateCameraButtonDidPress(_:)), for: .touchUpInside)
        button.imageView?.contentMode = .center
        
        return button
    }()
    
    weak var delegate: TopViewDelegate?
    
    // MARK: - Initializers
    
    public init(configuration: ImagePickerConfiguration? = nil) {
        if let configuration = configuration {
            self.configuration = configuration
        }
        super.init(frame: .zero)
        configure()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        var buttons: [UIButton] = [flashButton]
        
        if configuration.canRotateCamera {
            buttons.append(rotateCamera)
        }
        
        for button in buttons {
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.5
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            button.layer.shadowRadius = 1
            button.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
        }
        
        flashButton.isHidden = configuration.flashButtonAlwaysHidden
        
        setupConstraints()
    }
    
    // MARK: - Action methods
    
    @objc func flashButtonDidPress(_ button: UIButton) {
        currentFlashIndex += 1
        currentFlashIndex = currentFlashIndex % flashButtonTitles.count
        let newTitle = flashButtonTitles[currentFlashIndex]
        
        button.setImage(AssetManager.getImage(newTitle), for: UIControl.State())
        button.accessibilityLabel = "Flash mode is \(newTitle)"
        
        delegate?.flashButtonDidPress(newTitle)
    }
    
    @objc func rotateCameraButtonDidPress(_ button: UIButton) {
        delegate?.rotateDeviceDidPress()
    }
}

extension TopView {
    
    func setupConstraints() {
        addConstraint(NSLayoutConstraint(item: flashButton, attribute: .left,
                                         relatedBy: .equal, toItem: self, attribute: .left,
                                         multiplier: 1, constant: Dimensions.leftOffset))
        
        addConstraint(NSLayoutConstraint(item: flashButton, attribute: .centerY,
                                         relatedBy: .equal, toItem: self, attribute: .centerY,
                                         multiplier: 1, constant: 0))
        
        addConstraint(NSLayoutConstraint(item: flashButton, attribute: .width,
                                         relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
                                         multiplier: 1, constant: Dimensions.height))
        
        addConstraint(NSLayoutConstraint(item: flashButton, attribute: .height,
                                         relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
                                         multiplier: 1, constant: Dimensions.height))

        if configuration.canRotateCamera {
            addConstraint(NSLayoutConstraint(item: rotateCamera, attribute: .right,
                                             relatedBy: .equal, toItem: self, attribute: .right,
                                             multiplier: 1, constant: Dimensions.rightOffset))
            
            addConstraint(NSLayoutConstraint(item: rotateCamera, attribute: .centerY,
                                             relatedBy: .equal, toItem: self, attribute: .centerY,
                                             multiplier: 1, constant: 0))
            
            addConstraint(NSLayoutConstraint(item: rotateCamera, attribute: .width,
                                             relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
                                             multiplier: 1, constant: Dimensions.height))
            
            addConstraint(NSLayoutConstraint(item: rotateCamera, attribute: .height,
                                             relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
                                             multiplier: 1, constant: Dimensions.height))
        }
    }
}
