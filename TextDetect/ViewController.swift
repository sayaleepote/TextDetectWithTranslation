//
//  ViewController.swift
//  TextDetect
//
//  Created by Sayalee on 6/13/18.
//  Copyright © 2018 Assignment. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var detectedText: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var languagePickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var languagePicker: UIPickerView!
    @IBOutlet weak var languageSelectorButton: UIButton!
    @IBOutlet weak var translatedText: UILabel!
    
    let languages = ["Select Language", "Hindi", "French", "Italian", "German", "Japanese"]
    let languageCodes = ["hi", "hi", "fr", "it", "de", "ja"]

    lazy var vision = Vision.vision()
    var textDetector: VisionTextDetector?
    var pickerVisible: Bool = false
    var targetCode = "hi"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLanguagePicker()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Configuration
    func configureLanguagePicker() {
        languagePicker.dataSource = self
        languagePicker.delegate = self
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("couldn't load image")
        }
        imageView.image = image
        
        detectText(image: image)
    }
}

// MARK :- UIPickerViewDelegate

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languages[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        languageSelectorButton.setTitle(languages[row], for: .normal)
        targetCode = languageCodes[row]
    }
}

// MARK: - IBActions

extension ViewController {
    
    @IBAction func languageSelectorTapped(_ sender: Any) {
        
        if pickerVisible {
            languagePickerHeightConstraint.constant = 0
            pickerVisible = false
            translateText(detectedText: self.detectedText.text ?? "")
        } else {
            languagePickerHeightConstraint.constant = 150
            pickerVisible = true
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutSubviews()
            self.view.updateConstraints()
        }
    }
    
    @IBAction func cameraButtonTapped(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera)  else {
            let alert = UIAlertController(title: "No camera", message: "This device does not support camera.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        self.present(picker, animated: true, completion: nil)
    }
    
    @IBAction func photosButtonTapped(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary)  else {
            let alert = UIAlertController(title: "No photos", message: "This device does not support photos.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
}

// MARK: - Methods

extension ViewController {
    func detectText (image: UIImage) {
        
        textDetector = vision.textDetector()
        
        let visionImage = VisionImage(image: image)
        
        textDetector?.detect(in: visionImage) { (features, error) in
            guard error == nil, let features = features, !features.isEmpty else {
                return
            }
            
            debugPrint("Feature blocks in the image: \(features.count)")
            
            var detectedText = ""
            for feature in features {
                let value = feature.text
                detectedText.append("\(value) ")
            }

            self.detectedText.text = detectedText
            self.translateText(detectedText: detectedText)
        }
    }
    
    func translateText(detectedText: String) {
        
        guard !detectedText.isEmpty else {
            return
        }
        
        let task = try? GoogleTranslate.sharedInstance.translateTextTask(text: detectedText, targetLanguage: self.targetCode, completionHandler: { (translatedText: String?, error: Error?) in
            debugPrint(error?.localizedDescription)
            
            DispatchQueue.main.async {
                self.translatedText.text = translatedText
            }
            
        })
        task?.resume()
    }
}


