//
//  ChoicePhotoTools.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/13.
//

import UIKit
import PhotosUI

class ChoicePhotoTools: NSObject , PHPickerViewControllerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    
    
    var blockComplete:((UIImage)->())?

    
     func takePhoto(controller:UIViewController){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        
        // Don't try to force portrait mode - let device determine orientation
        // Don't set specific camera device or orientation settings
        
        // Check if camera is available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            controller.present(picker, animated: true)
        } else {
            // Show alert if camera isn't available
            let alert = UIAlertController(
                title: "Camera Unavailable",
                message: "Camera is not available on this device or cannot be accessed.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            controller.present(alert, animated: true)
        }
    }
    
     func choicePhoto(controller:UIViewController){
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
         controller.present(picker, animated: true)

    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            DispatchQueue.main.async {
                if let image = image as? UIImage {
                    if((self?.blockComplete) != nil){
                        self?.blockComplete!(image)
                    }
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController,didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
           picker.dismiss(animated: true)
           if let image = info[.originalImage] as? UIImage {
               if((self.blockComplete) != nil){
                   self.blockComplete!(image)
               }
           }
       }
       
       func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
           picker.dismiss(animated: true)
       }


}
