//
//  ImagePickerConfiguration.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit

public struct ImagePickerConfiguration {
    
    // MARK: Colors
    
    public var backgroundColor = UIColor(red: 0.15, green: 0.19, blue: 0.24, alpha: 1)
    public var gallerySeparatorColor = UIColor.black.withAlphaComponent(0.6)
    public var mainColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
    public var bottomContainerColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
    
    // MARK: Fonts
    public var numberLabelFont = UIFont.systemFont(ofSize: 19, weight: .bold)
    public var finshButtonFont = UIFont.systemFont(ofSize: 19, weight: .medium)
    
    // MARK: Titles
    
    public var OKButtonTitle = "OK"
    public var cancelButtonTitle = "Cancel"
    public var finishButtonTitle = "Done"
    public var requestPermissionTitle = "Permission denied"
    public var requestPermissionMessage = "Please, allow the application to access to your photo library."
    
    // MARK: Dimensions
    public var cellSpacing: CGFloat = 2
    public var cellColumn: Int = 3
    
    // MARK: Custom behaviour
    
    public var imageLimit: Int = 0
    public var canRotateCamera = true
    public var recordLocation = true
    public var allowMultipleSelection = true
    public var allowVideoSelection = false
    public var showImageCount = true
    public var flashButtonAlwaysHidden = false
    public var managesAudioSession = true
    public var allowPinchToZoom = true
    public var allowVolumeWhenTakingPicture = true
    public var useLowResolutionPreviewImage = false
    public var selectedBackgroundView: (() -> UIView)? = nil
    
    public init() { }
}

