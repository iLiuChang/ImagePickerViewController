//
//  AssetManager.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit
import Photos

open class AssetManager {
    
    public static func getImage(_ name: String) -> UIImage {
        let traitCollection = UITraitCollection(displayScale: 3)
        var bundle = Bundle(for: AssetManager.self)
        
        if let resource = bundle.resourcePath, let resourceBundle = Bundle(path: resource + "/ImagePickerViewController.bundle") {
            bundle = resourceBundle
        }
        
        return UIImage(named: name, in: bundle, compatibleWith: traitCollection) ?? UIImage()
    }
    
    public static func fetch(withImageConfiguration configuration: ImagePickerConfiguration, _ completion: @escaping (_ assets: [PHAsset]) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        DispatchQueue.global(qos: .background).async {
            let fetchResult = configuration.allowVideoSelection
            ? PHAsset.fetchAssets(with: options)
            : PHAsset.fetchAssets(with: .image, options: options)
            
            if fetchResult.count > 0 {
                var assets = [PHAsset]()
                fetchResult.enumerateObjects({ object, _, _ in
                    assets.insert(object, at: 0)
                })
                
                DispatchQueue.main.async {
                    completion(assets)
                }
            }
        }
    }
    
    public static func resolveAsset(_ asset: PHAsset, size: CGSize = CGSize(width: 720, height: 1280), shouldPreferLowRes: Bool = false, completion: @escaping (_ image: UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = shouldPreferLowRes ? .fastFormat : .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, info in
            if let info = info, info["PHImageFileUTIKey"] == nil {
                DispatchQueue.main.async(execute: {
                    completion(image)
                })
            }
        }
    }
    
    public static func resolveAssets(_ assets: [PHAsset], size: CGSize = CGSize(width: 720, height: 1280)) -> [MediaItem] {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        var images = [MediaItem]()
        for asset in assets {
            imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
                if let image = image {
                    images.append(MediaItem(image: image, asset: asset))
                }
            }
        }
        return images
    }
}
