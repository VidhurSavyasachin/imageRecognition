//
//  ViewController.swift
//  Find the Flower
//
//  Created by Vidhur Savyasachin on 6/28/19.
//  Copyright © 2019 Vidhur Savyasachin. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SwiftyJSON
import Alamofire
import SDWebImage
import ColorThiefSwift
class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet weak var changeViewColor: UIView!
    
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    var flowerName: String = ""
    var content: String = ""
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detailsOfFlower: UITextView!
   //[yourTextView setContentOffset: CGPointMake(x,y) animated:BOOL];
    
    @IBOutlet weak var NameOfTheFlower: UILabel!
    let imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        NameOfTheFlower.isHidden = true
        detailsOfFlower.isHidden = true
        self.detailsOfFlower.contentInset = UIEdgeInsets(top: -7.0,left: 0.0,bottom: 0,right: 0.0)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let Userimage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
//            imageView.image = Userimage
           
            guard let ciImage = CIImage(image: Userimage) else{
                fatalError("Could not convert to CI image")
            }
            detect(image: ciImage)
            
        } else{
            print("error picking image")
        }
        print(flowerName)
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Loading model Failed")
        }
        let request = VNCoreMLRequest(model: model) {
            (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else{
                fatalError("Error Loading Results")
            }
            if let firstResult = results.first {
                self.flowerName = firstResult.identifier
                self.navigationItem.title = "\(self.flowerName.capitalized)"
                self.getValue()
            }
            
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do{
            try handler.perform([request])
        }catch {
            print(error)
        }
    
    }
    func APIConnection(URL: String, parameters: [String:String]){
    
        Alamofire.request(URL,method: .get,parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess{
                print("Success Got data")
             
                let infoData: JSON = JSON(response.result.value)
                let pageId = infoData["query"]["pageids"][0].stringValue
                let extract = infoData["query"]["pages"][pageId]["extract"].stringValue
                let titleOfFlower = infoData["query"]["pages"][pageId]["title"].stringValue
                let flowerImage = infoData["query"]["pages"][pageId]["thumbnail"]["source"].url
                self.imageView.sd_setImage(with: flowerImage, completed: { (image, error, cache, url) in
                    if let currentImage = self.imageView.image{
                        guard let dominantColor = ColorThief.getColor(from: currentImage) else {
                            fatalError("Can't get dominant color")
                        }
                        DispatchQueue.main.async {
                            self.navigationController?.navigationBar.isTranslucent = true
                            self.navigationController?.navigationBar.barTintColor = dominantColor.makeUIColor()
                            self.changeViewColor.backgroundColor = dominantColor.makeUIColor()
                        }
                    }else{
                        self.imageView.image = image
                        self.detailsOfFlower.text = "Could not get info of flower in wikipedia"
                    }
                })
                self.NameOfTheFlower.isHidden = false
                self.detailsOfFlower.isHidden = false
                self.NameOfTheFlower.text = titleOfFlower
                self.detailsOfFlower.text = extract
                print(infoData)
               
            }else{
                print("Error \(response.result.error)")
            }
        }
      
    }
    func getValue(){
        
          let URL = "https://en.wikipedia.org/w/api.php"
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]

        APIConnection(URL: URL,parameters: parameters)
    }
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
       present(imagePicker,animated: true,completion: nil)
        
    }
}

extension String {
    func replace(string:String, replacement:String) -> String {
        return self.replacingOccurrences(of: string, with: replacement, options: NSString.CompareOptions.literal, range: nil)
    }
    
    func removeWhitespace() -> String {
        return self.replace(string: " ", replacement: "")
    }
}
