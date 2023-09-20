//
//  BottomContainerView.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit

protocol BottomContainerViewDelegate: AnyObject {
    
    func pickerButtonDidPress()
    func doneButtonDidSelect()
    func cancelButtonDidSelect()
    func imageStackViewDidPress()
}

open class BottomContainerView: UIView {
    
    struct Dimensions {
        static let height: CGFloat = 100
    }
    
    var configuration = ImageConfiguration()
    
    lazy var pickerButton: ButtonPicker = { [unowned self] in
        let pickerButton = ButtonPicker(configuration: self.configuration)
        pickerButton.setTitleColor(UIColor.white, for: UIControl.State())
        pickerButton.delegate = self
        pickerButton.numberLabel.isHidden = !self.configuration.showImageCount
        
        return pickerButton
    }()
    
    lazy var borderPickerButton: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = ButtonPicker.Dimensions.borderWidth
        view.layer.cornerRadius = ButtonPicker.Dimensions.buttonBorderSize / 2
        
        return view
    }()
    
    open lazy var doneButton: UIButton = { [unowned self] in
        let button = UIButton()
        button.setTitle(self.configuration.cancelButtonTitle, for: UIControl.State())
        button.titleLabel?.font = self.configuration.doneButton
        button.addTarget(self, action: #selector(doneButtonDidSelect(_:)), for: .touchUpInside)
        
        return button
    }()
    
    lazy var stackView = ImageStackView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
    
    lazy var topSeparator: UIView = { [unowned self] in
        let view = UIView()
        view.backgroundColor = self.configuration.backgroundColor
        
        return view
    }()
    
    lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(handleTapGestureRecognizer(_:)))
        
        return gesture
    }()
    
    weak var delegate: BottomContainerViewDelegate?
    var pastCount = 0
    
    // MARK: Initializers
    
    public init(configuration: ImageConfiguration? = nil) {
        if let configuration = configuration {
            self.configuration = configuration
        }
        super.init(frame: .zero)
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        [borderPickerButton, pickerButton, doneButton, stackView, topSeparator].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        backgroundColor = configuration.backgroundColor
        stackView.accessibilityLabel = "Image stack"
        stackView.addGestureRecognizer(tapGestureRecognizer)
        
        setupConstraints()
    }
    
    // MARK: - Action methods
    
    @objc func doneButtonDidSelect(_ button: UIButton) {
        if button.currentTitle == configuration.cancelButtonTitle {
            delegate?.cancelButtonDidSelect()
        } else {
            delegate?.doneButtonDidSelect()
        }
    }
    
    @objc func handleTapGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
        delegate?.imageStackViewDidPress()
    }
    
    fileprivate func animateImageView(_ imageView: UIImageView) {
        imageView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: 0.3, animations: {
            imageView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                imageView.transform = CGAffineTransform.identity
            })
        })
    }
}

// MARK: - ButtonPickerDelegate methods

extension BottomContainerView: ButtonPickerDelegate {
    
    func buttonDidPress() {
        delegate?.pickerButtonDidPress()
    }
}

extension BottomContainerView {
    
    func setupConstraints() {
        
        for attribute: NSLayoutConstraint.Attribute in [.centerX, .centerY] {
            addConstraint(NSLayoutConstraint(item: pickerButton, attribute: attribute,
                                             relatedBy: .equal, toItem: self, attribute: attribute,
                                             multiplier: 1, constant: 0))
            
            addConstraint(NSLayoutConstraint(item: borderPickerButton, attribute: attribute,
                                             relatedBy: .equal, toItem: self, attribute: attribute,
                                             multiplier: 1, constant: 0))
        }
        
        for attribute: NSLayoutConstraint.Attribute in [.width, .left, .top] {
            addConstraint(NSLayoutConstraint(item: topSeparator, attribute: attribute,
                                             relatedBy: .equal, toItem: self, attribute: attribute,
                                             multiplier: 1, constant: 0))
        }
        
        for attribute: NSLayoutConstraint.Attribute in [.width, .height] {
            addConstraint(NSLayoutConstraint(item: pickerButton, attribute: attribute,
                                             relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
                                             multiplier: 1, constant: ButtonPicker.Dimensions.buttonSize))
            
            addConstraint(NSLayoutConstraint(item: borderPickerButton, attribute: attribute,
                                             relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
                                             multiplier: 1, constant: ButtonPicker.Dimensions.buttonBorderSize))
            
            addConstraint(NSLayoutConstraint(item: stackView, attribute: attribute,
                                             relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
                                             multiplier: 1, constant: ImageStackView.Dimensions.imageSize))
        }
        
        addConstraint(NSLayoutConstraint(item: doneButton, attribute: .centerY,
                                         relatedBy: .equal, toItem: self, attribute: .centerY,
                                         multiplier: 1, constant: 0))
        
        addConstraint(NSLayoutConstraint(item: stackView, attribute: .centerY,
                                         relatedBy: .equal, toItem: self, attribute: .centerY,
                                         multiplier: 1, constant: -2))
        
        let screenSize = Helper.screenSizeForOrientation()
        
        addConstraint(NSLayoutConstraint(item: doneButton, attribute: .centerX,
                                         relatedBy: .equal, toItem: self, attribute: .right,
                                         multiplier: 1, constant: -(screenSize.width - (ButtonPicker.Dimensions.buttonBorderSize + screenSize.width)/2)/2))
        
        addConstraint(NSLayoutConstraint(item: stackView, attribute: .centerX,
                                         relatedBy: .equal, toItem: self, attribute: .left,
                                         multiplier: 1, constant: screenSize.width/4 - ButtonPicker.Dimensions.buttonBorderSize/3))
        
        addConstraint(NSLayoutConstraint(item: topSeparator, attribute: .height,
                                         relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
                                         multiplier: 1, constant: 1))
    }
}
