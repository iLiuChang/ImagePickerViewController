//
//  ViewController.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit

class ViewController: UIViewController {
    let button = UIButton()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        button.backgroundColor = .black.withAlphaComponent(0.2)
        button.setTitle("＋", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.frame = CGRectMake(100, 100, 200, 200)
        button.addTarget(self, action: #selector(click(button:)), for: .touchUpInside)
        view.addSubview(button)
    }
    
    
    @objc func click(button: UIButton) {
        var config = ImagePickerConfiguration()
        config.allowMultiplePhotoSelection = false
        config.allowVideoSelection = true
        config.cellColumn = 4
        config.selectedBackgroundView = {
            let button = UIButton()
            button.setBackgroundImage(AssetManager.getImage("focusIcon"), for: .normal)
            return button
        }
        let imagePicker = ImagePickerViewController(configuration: config)
        imagePicker.imageLimit = 7
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)

    }
}

extension ViewController: ImagePickerViewControllerDelegate {
    func didLookAtPicking(_ imagePicker: ImagePickerViewController, items: [MediaItem]) {
        imagePicker.dismiss(animated: true, completion: nil)
        button.setImage(items.first?.image, for: .normal)
    }
    
    func didFinishPicking(_ imagePicker: ImagePickerViewController, items: [MediaItem]) {
        imagePicker.dismiss(animated: true, completion: nil)
        button.setImage(items.first?.image, for: .normal)
    }

    func didCancelPicking(_ imagePicker: ImagePickerViewController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
   
    
}
