//
//  ViewController.swift
//  MemeMe
//
//  Created by Ahmed Tawfik on 9/12/17.
//  Copyright © 2017 Fox Apps. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    // MARK: Model
    struct Meme {
        var topText: String
        var bottomText: String
        var originalImage: UIImage
        var memedImage: UIImage
    }
    
    // MARK: IB Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var navigationBar: UIToolbar!
    @IBOutlet weak var toolBar: UIToolbar!

    // MARK: Constants
    let memeTextAttributes:[String:Any] = [
        NSStrokeColorAttributeName: UIColor.black,
        NSForegroundColorAttributeName: UIColor.white,
        NSFontAttributeName: UIFont(name: "Impact", size: 40)!,
        NSStrokeWidthAttributeName: -3.0]
    
    // MARK: Alerts
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let PhotoLibraryDisabledTitle = "Photo Library Access is Disabled"
        static let PhotoLibraryDisabledMessage = "You've disabled this app from accessing the photo library. Check Settings."
        static let CameraDisabledTitle = "Camera Access is Disabled"
        static let CameraDisabledMessage = "You've disabled this app from accessing the camera. Check Settings."
        static let PickingImageFailedTitle = "Picking Image Failed"
        static let PickingImageFailedMessage = "Something went wrong with your picture."
    }

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        topTextField.defaultTextAttributes = memeTextAttributes
        bottomTextField.defaultTextAttributes = memeTextAttributes
        topTextField.textAlignment = .center
        bottomTextField.textAlignment = .center
        topTextField.delegate = self
        bottomTextField.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        shareButton.isEnabled = imageView.image != nil
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeToKeyboardNotifications()
    }

    // MARK: IB Actions
    @IBAction func pickAnImageFromAlbum(_ sender: UIBarButtonItem) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            imagePickingFromSourceType(.photoLibrary)
        case .denied:
            showAlert(Alerts.PhotoLibraryDisabledTitle, message: Alerts.PhotoLibraryDisabledMessage)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.imagePickingFromSourceType(.photoLibrary)
                    }
                } else {
                        DispatchQueue.main.async {
                            self.showAlert(Alerts.PhotoLibraryDisabledTitle, message: Alerts.PhotoLibraryDisabledMessage)
                        }
                    }
                })
        case .restricted:
            showAlert(Alerts.PhotoLibraryDisabledTitle, message: Alerts.PhotoLibraryDisabledMessage)
        }
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: UIBarButtonItem) {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            imagePickingFromSourceType(.camera)
        case .denied:
            showAlert(Alerts.CameraDisabledTitle, message: Alerts.CameraDisabledMessage)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.imagePickingFromSourceType(.camera)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(Alerts.CameraDisabledTitle, message: Alerts.CameraDisabledMessage)
                    }
                }
            })
        case .restricted:
            showAlert(Alerts.CameraDisabledTitle, message: Alerts.CameraDisabledMessage)
        }
    }
    
    @IBAction func shareImage(_ sender: UIBarButtonItem) {
        let memedImage = generateMemedImage()
        let activityController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        present(activityController, animated: true) {
            self.save()
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        if topTextField.isFirstResponder || bottomTextField.isFirstResponder {
            topTextField.resignFirstResponder()
            bottomTextField.resignFirstResponder()
        } else {
            resetTheImageView()
            resetTheTextField()
        }
    }
    
    // MARK: Reset the Meme
    private func resetTheImageView() {
        imageView.image = nil
        shareButton.isEnabled = false
    }
    private func resetTheTextField() {
        topTextField.text = "TOP"
        bottomTextField.text = "BOTTOM"
    }

    // MARK: Image Picking
    func imagePickingFromSourceType(_ sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: Keyboard Moving View
    // Show/Hide the Keyboard
    func keyboardWillShow(_ notification: Notification) {
        view.frame.origin.y -= getKeyboardHeight(notification)
    }
    
    func keyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    // MARK: Generate the Meme
    func generateMemedImage() -> UIImage {
        //Hide the ToolBar
        navigationBar.isHidden = true
        toolBar.isHidden = true
        
        //Render view to an image
        UIGraphicsBeginImageContext(view.frame.size)
        view.drawHierarchy(in: view.frame, afterScreenUpdates: true)
        let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //Show the ToolBar
        navigationBar.isHidden = false
        toolBar.isHidden = false

        return memedImage
    }
    
    func save() {
        // Create the meme
        let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imageView.image!, memedImage: generateMemedImage())
        UIImageWriteToSavedPhotosAlbum(meme.memedImage, nil, nil, nil)
    }


    
    // MARK: Image Picker Controller Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            imageView.image = image
            resetTheTextField()
        } else {
            showAlert(Alerts.PickingImageFailedTitle, message: Alerts.PickingImageFailedMessage)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Text Field Delegate Methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.accessibilityIdentifier == "bottomTextField" {
            unsubscribeToKeyboardNotifications()
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "TOP" || textField.text == "BOTTOM" {
            textField.text = ""
        }
        if textField.accessibilityIdentifier == "bottomTextField" {
            subscribeToKeyboardNotifications()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if textField.text == "" {
            if textField.accessibilityIdentifier == "topTextField" {
                textField.text = "TOP"
            } else if textField.accessibilityIdentifier == "bottomTextField" {
                textField.text = "BOTTOM"
            }

        }
    }
    
    // MARK: Show Alert Function
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}
