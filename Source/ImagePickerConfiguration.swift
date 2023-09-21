//
//  ImagePickerConfiguration.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import AVFoundation
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
    public var flashButtonFont = UIFont.systemFont(ofSize: 12, weight: .medium)
    
    // MARK: Titles
    
    public var OKButtonTitle = "OK"
    public var cancelButtonTitle = "Cancel"
    public var doneButtonTitle = "Done"
    public var requestPermissionTitle = "Permission denied"
    public var requestPermissionMessage = "Please, allow the application to access to your photo library."
    
    // MARK: Dimensions
    public var cellSpacing: CGFloat = 2
    public var cellColumn: Int = 3
    
    // MARK: Custom behaviour
    
    public var canRotateCamera = true
    public var recordLocation = true
    public var allowMultiplePhotoSelection = true
    public var allowVideoSelection = false
    public var showImageCount = true
    public var flashButtonAlwaysHidden = false
    public var managesAudioSession = true
    public var allowPinchToZoom = true
    public var allowedOrientations = UIInterfaceOrientationMask.all
    public var allowVolumeWhenTakingPicture = true
    public var useLowResolutionPreviewImage = false
    public var selectedBackgroundView: (() -> UIView)? = nil
    
    public init() { }
}

extension ImagePickerConfiguration {
    
    public var rotationTransform: CGAffineTransform {
        let currentOrientation = UIDevice.current.orientation
        
        // check if current orientation is allowed
        switch currentOrientation {
        case .portrait:
            if allowedOrientations.contains(.portrait) {
                Helper.previousOrientation = currentOrientation
            }
        case .portraitUpsideDown:
            if allowedOrientations.contains(.portraitUpsideDown) {
                Helper.previousOrientation = currentOrientation
            }
        case .landscapeLeft:
            if allowedOrientations.contains(.landscapeLeft) {
                Helper.previousOrientation = currentOrientation
            }
        case .landscapeRight:
            if allowedOrientations.contains(.landscapeRight) {
                Helper.previousOrientation = currentOrientation
            }
        default: break
        }
        
        // set default orientation if current orientation is not allowed
        if Helper.previousOrientation == .unknown {
            if allowedOrientations.contains(.portrait) {
                Helper.previousOrientation = .portrait
            } else if allowedOrientations.contains(.landscapeLeft) {
                Helper.previousOrientation = .landscapeLeft
            } else if allowedOrientations.contains(.landscapeRight) {
                Helper.previousOrientation = .landscapeRight
            } else if allowedOrientations.contains(.portraitUpsideDown) {
                Helper.previousOrientation = .portraitUpsideDown
            }
        }
        
        return Helper.getTransform(fromDeviceOrientation: Helper.previousOrientation)
    }
}
