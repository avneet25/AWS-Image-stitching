//
//  ViewController.swift
//  Image stiching
//
//  Created by Avneet Kaur on 2021-11-23.
//

import UIKit
import AWSS3
import AWSCognito
import AWSCore

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    @IBOutlet weak var goBtn: UIButton!
    
    let bucketName = "panorama359"
    var url: URL!
    var newImageView = UIImageView()
    @IBOutlet weak var cv: UICollectionView!
    @IBOutlet weak var cvHgtConstant: NSLayoutConstraint!
    
    var imgArr = [UIImage(), UIImage(), UIImage()]
    var index = Int()
    override func viewDidLoad() {
        super.viewDidLoad()
        cvHgtConstant.constant = ((self.view.frame.width - 32)/3) + 16
        goBtn.layer.cornerRadius = 20
        
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        if imgArr[indexPath.row] != UIImage() {
            cell.img.image = imgArr[indexPath.row]
            cell.plus.isHidden = true
        }
        else{
            cell.img.image = UIImage()
            cell.plus.isHidden = false
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize (width: (self.view.frame.width - 32)/3, height: (self.view.frame.width - 32)/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if imgArr[indexPath.row] != UIImage() {
            let scrollview = UIScrollView(frame: UIScreen.main.bounds)
            scrollview.alwaysBounceVertical = false
            scrollview.alwaysBounceHorizontal = false
            
            scrollview.delegate = self
            scrollview.addSubview(newImageView)
            newImageView.image = imgArr[indexPath.row]
            newImageView.frame = UIScreen.main.bounds
            newImageView.backgroundColor = .black
            newImageView.contentMode = .scaleAspectFit
            newImageView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage(_:)))
            scrollview.maximumZoomScale = 5.0
            scrollview.minimumZoomScale = 1.0
            scrollview.addGestureRecognizer(tap)
            
            self.view.addSubview(scrollview)
        }
        else {
        index = indexPath.row
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        
            }
        
        }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [self] in
            let img = info[.originalImage] as! UIImage
            imgArr[index] = img
            saveImageToDocumentDirectory(img)
            uploadFile(img: imgArr[index])
            cv.reloadData()
        }
    }
    
    func saveImageToDocumentDirectory(_ chosenImage: UIImage) -> String {
            let directoryPath =  NSHomeDirectory().appending("/Documents/")
            if !FileManager.default.fileExists(atPath: directoryPath) {
                do {
                    try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error)
                }
            }
            let filename = "img\(index)"
            let filepath = directoryPath.appending(filename)
            url = NSURL.fileURL(withPath: filepath)
            do {
                try chosenImage.jpegData(compressionQuality: 1.0)?.write(to: url, options: .atomic)
                            return String.init("/Documents/\(filename)")
            } catch {
                print(error)
                print("file cant not be save at path \(filepath), with error : \(error)");
                return filepath
            }
        }
    
    @objc func dismissFullscreenImage (_ sender: UITapGestureRecognizer){
        sender.view?.removeFromSuperview()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return newImageView
    }
    
    @IBAction func goAction(_ sender: Any) {
    performSegue(withIdentifier: "resultSegue", sender: nil)
    }
    
    func uploadFile(img: UIImage) {
        //1
        let key = "img/(index)"
        
        let request = AWSS3TransferManagerUploadRequest()!
        request.bucket = bucketName  //3
        request.key = "panorama"  //4
        request.body = url
        request.acl = .publicReadWrite  //5
        
        //6
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(request).continueWith(executor: AWSExecutor.mainThread()) { (task) -> Any? in
            if let error = task.error {
                print(error)
            }
            if task.result != nil {   //7
                print("Uploaded \(key)")
                //do any task
            }
            
            return nil
        }
        
    }
}

