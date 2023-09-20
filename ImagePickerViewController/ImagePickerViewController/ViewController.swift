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
        var config = ImageConfiguration()
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

extension ViewController: ImagePickerDelegate {
    func stackButtonDidSelect(_ imagePicker: ImagePickerViewController, images: [UIImage]) {
        imagePicker.dismiss(animated: true, completion: nil)
        button.setImage(images.first, for: .normal)
    }
    
    func doneButtonDidSelect(_ imagePicker: ImagePickerViewController, images: [UIImage]) {
        imagePicker.dismiss(animated: true, completion: nil)
        button.setImage(images.first, for: .normal)
    }
    
    func cancelButtonDidSelect(_ imagePicker: ImagePickerViewController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
   
    
}
