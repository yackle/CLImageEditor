//
//  ViewController.swift
//  CLImageEditor-Swift
//
//  Created by dirtbag on 3/16/19.
//  Copyright © 2019 dirtbag. All rights reserved.
//

import UIKit
import CLImageEditor

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITabBarDelegate,  CLImageEditorDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let STORED_IMAGE_NAME = "/stored_image_name.png"
    
    /// load any stored image
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var image = readImageFromStorage()
        if image == nil {
            image = UIImage(named: "default.jpg")
        }
        imageView.image = image
        
    }
    
    /// called when an image has been chosen
    /// here we start the editor with the new image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        let editor = CLImageEditor(image: image, delegate: self)
        
        picker.pushViewController(editor!, animated: true)
        
    }
    
    /// called when editor completes
    func imageEditor(_ editor: CLImageEditor!, didFinishEditingWith image: UIImage!) {
        
        imageView.image = image
        editor.dismiss(animated: true, completion: nil)
    }
    
    // mark - Tab Bar Delegate
    @objc func deselectTabBarItem(tabBar: UITabBar) {
        
        tabBar.selectedItem = nil
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        self.perform(#selector(deselectTabBarItem(tabBar:)), with: tabBar, afterDelay: 0.2)
        
        switch (item.tag) {
        case 0:
            self.newImage()
            break
            
        case 1:
            self.editImage()
            break
            
        case 2:
            self.saveImage()
            break
            
        default:
            break
        }
    }
    
    
    /// mark - Tab bar actions
    
    /// get a new image to edit
    func newImage() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
            
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /// edit current image
    func editImage() {
        
        if (imageView.image != nil) {
            let editor = CLImageEditor(image: imageView.image, delegate: self)
            self.present(editor!, animated: true, completion: nil)
            
        } else {
            newImage()
        }
    }
    
    /// save current image
    func saveImage() {
        
        if let image = imageView.image {

            let success = writeImageToStorage(image: image)

            if success {
                
                let alert = UIAlertController(title: "Saved successfully", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            } else {
                // TODO: popup alert
                print ("Failed to save image.")
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    /// Read image from local storage
    func readImageFromStorage() -> UIImage? {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        if documentsPath.count > 0 {
            let documentDirectory = documentsPath[0]
            let restorePath = documentDirectory + STORED_IMAGE_NAME
            
            let image = UIImage(contentsOfFile: restorePath)
            
            return image
        } else {
            return nil
        }
    }
    
    // write user image to local storage
    func writeImageToStorage(image: UIImage) -> Bool {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        if documentsPath.count > 0 {
            
            let documentDirectory = documentsPath[0]
            let savePath = documentDirectory + STORED_IMAGE_NAME
            
            if let imageData = image.pngData() {
                
                do {
                    
                    // write image to disk
                    try imageData.write(to: URL(fileURLWithPath: savePath))
                    
                } catch {
                    return false
                }
            }
        }
        return true
    }
}

