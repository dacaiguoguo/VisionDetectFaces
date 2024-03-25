//
//  ViewController.swift
//  VisionTest
//
//  Created by yanguo sun on 2024/3/25.
//

import UIKit
import Vision


func detectFaces(in image: UIImage) {
    guard let cgImage = image.cgImage else { return }

    let request = VNDetectFaceRectanglesRequest { (request, error) in
        if let error = error {
            print("Face detection error: \(error)")
            return
        }
        
        request.results?.forEach({ result in
            guard let faceObservation = result as? VNFaceObservation else { return }
            print("Found a face at \(faceObservation.boundingBox)")
        })
    }
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("Failed to perform face detection: \(error)")
    }
}


func detectFaces(in image: UIImage, completion: @escaping (Int) -> Void) {
    guard let cgImage = image.cgImage else {
        completion(0)
        return
    }

    let request = VNDetectFaceRectanglesRequest { (request, error) in
        guard error == nil else {
            print("Face detection error: \(error!.localizedDescription)")
            completion(0)
            return
        }
        
        let faceCount = request.results?.count ?? 0
        completion(faceCount)
    }
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("Failed to perform face detection: \(error)")
        completion(0)
    }
}


import UIKit
import Vision
// 给detectFacesAndShowAlertIfNone 这个方法增加日志 记录执行时间
func showAlert(withMessage message: String, viewController: UIViewController) {
    let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "好的", style: .default))
    viewController.present(alert, animated: true)
}

func detectFacesAndShowAlertIfNone(in image: UIImage, viewController: UIViewController, completion: @escaping (Int) -> Void) {
    let startTime = Date() // 记录开始时间

    DispatchQueue.global(qos: .userInitiated).async {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                let endTime = Date().timeIntervalSince(startTime) // 计算执行时间
                print("人脸检测总耗时：\(endTime)秒")
                completion(-1)
                // showAlert(in: viewController, withMessage: "无法处理图像")
            }
            return
        }

        let request = VNDetectFaceRectanglesRequest { (request, error) in
            guard error == nil else {
                DispatchQueue.main.async {
                    let endTime = Date().timeIntervalSince(startTime) // 计算执行时间
                    print("人脸检测总耗时：\(endTime)秒")
                    completion(-1)
                    showAlert(in: viewController, withMessage: "人脸检测出错: \(error!.localizedDescription)")
                }
                return
            }
            
            let faceCount = request.results?.count ?? 0
            DispatchQueue.main.async {
                let endTime = Date().timeIntervalSince(startTime) // 计算执行时间
                print("人脸检测总耗时：\(endTime)秒")
                completion(faceCount)
            }
//            if faceCount == 0 {
//                DispatchQueue.main.async {
//                    showAlert(in: viewController, withMessage: "未检测到人脸")
//                }
//            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                let endTime = Date().timeIntervalSince(startTime) // 计算执行时间
                print("人脸检测总耗时：\(endTime)秒")
                completion(-1)
                // showAlert(in: viewController, withMessage: "执行人脸检测失败: \(error)")
            }
        }
    }
}

func showAlert(in viewController: UIViewController, withMessage message: String) {
    let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "好的", style: .default))
    viewController.present(alert, animated: true)
}

class ViewController2: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let tt = UIImage(named: "Business.jpg") {
            detectFaces(in: tt) { count in
                print("Found face \(count)")
            }
        }
        if let tt = UIImage(named: "input") {
            detectFaces(in: tt) { count in
                print("Found face \(count)")
            }
        }
        if let tt = UIImage(named: "launchIcon3@2x.png") {
            detectFacesAndShowAlertIfNone(in: tt, viewController: self) { count in
                if count > 0 {
                    showAlert(in: self, withMessage: "检测到人脸:\(count)")
                } else {
                    showAlert(in: self, withMessage: "没有检测到人脸")
                }
            }
        }
    }
    
}

import UIKit
import PhotosUI
import Vision

class ViewController: UIViewController, PHPickerViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Detect Face"
//        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "add"), style: .done, target: self, action: #selector(showPhotoPicker))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showPhotoPicker))

    }
    
    
    @objc func showPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1 // Limit to one selection
        configuration.filter = .images // Only show images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let itemProvider = results.first?.itemProvider else { return }
        
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                DispatchQueue.main.async {
                    if let weakSelf = self {
                        if let image = image as? UIImage {
                            detectFacesAndShowAlertIfNone(in: image, viewController: weakSelf) { count in
                                if count > 0 {
                                    showAlert(in: weakSelf, withMessage: "检测到人脸:\(count)")
                                } else {
                                    showAlert(in: weakSelf, withMessage: "没有检测到人脸")
                                }
                            }
                        } else {
                            showAlert(in: weakSelf, withMessage: "无法加载图像")
                        }
                    }
                }
            }
        }
    }
    

    

}

