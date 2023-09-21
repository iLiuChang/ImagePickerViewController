//
//  DeviceHelper.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit
import AVFoundation

struct DeviceHelper {
    
    static var previousOrientation = UIDeviceOrientation.unknown
        
    static func getVideoOrientation(fromDeviceOrientation orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    static func videoOrientation() -> AVCaptureVideoOrientation {
        return getVideoOrientation(fromDeviceOrientation: previousOrientation)
    }
    
    static func screenSizeForOrientation() -> CGSize {
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            return CGSize(width: UIScreen.main.bounds.height,
                          height: UIScreen.main.bounds.width)
        default:
            return UIScreen.main.bounds.size
        }
    }
}
