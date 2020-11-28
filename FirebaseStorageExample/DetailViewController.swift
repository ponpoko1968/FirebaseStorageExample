//
//  DetailViewController.swift
//  FirebaseStorageExample
//
//  Created by 越智修司 on 2020/11/28.
//  Copyright © 2020 shuji ochi. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

import FirebaseStorage

class DetailViewController: UIViewController  {

    var fileSize:Int64 = 0

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var progressStackView: UIStackView!
    @IBOutlet weak var progressWidth: NSLayoutConstraint!
    @IBOutlet weak var progressLabel: UILabel!
    @IBAction func startUpload(_ sender: Any) {
        var configuration = PHPickerConfiguration()
        // 動画を選択
        configuration.filter = .videos
        // 1つだけ選択可能
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.present(picker, animated: true){
                }
            }
        }
    }
    var uploadTask : StorageUploadTask?

    @IBAction func cancelTask(_ sender: Any) {
        uploadTask?.cancel()
    }

    func configureView() {

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }


}

extension DetailViewController: PHPickerViewControllerDelegate  {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        log.debug("\(String(describing: results.first?.assetIdentifier))")

        _ = results.first?.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.mpeg-4"){ url, error in

            // このクロージャを出るとファイルが消されるので別のフォルダにコピーし、これをアップロードする
            let cacheUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let temporaryFileURL = cacheUrl.appendingPathComponent(url!.lastPathComponent)
            do {
                log.debug("\(url!) to \(temporaryFileURL)")
                do {
                    try FileManager.default.removeItem(at: temporaryFileURL)
                }catch{
                    // 無ければ無いでいい
                }
                try FileManager.default.copyItem(at: url!, to: temporaryFileURL)
            }catch{
                log.debug("failed to handle file \(error)")
                return
            }


            log.debug("\(String(describing: url))")
            log.debug("\(String(describing: error))")
            let storage = Storage.storage()
            // Create a root reference
            let storageRef = storage.reference()

            let fileName = url?.lastPathComponent
            // Create a reference to the file you want to upload
            let riversRef = storageRef.child("public/\(fileName!)")

            // Upload the file
            self.uploadTask = riversRef.putFile(from: temporaryFileURL, metadata: nil) { metadata, error in
              guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                log.debug("\(String(describing: error))")
                return
              }
              // Metadata contains file metadata such as size, content-type.
              self.fileSize = metadata.size
              log.debug("\(metadata.size)")
              self.startButton.isEnabled = true
              self.cancelButton.isEnabled = false
              self.progressLabel.text = nil


            }
            let progress = self.uploadTask?.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else{
                    return
                }
                log.debug("progress=\(progress.completedUnitCount) / \(progress.totalUnitCount)")

                self.startButton.isEnabled = progress.isFinished || progress.isCancelled
                self.cancelButton.isEnabled = progress.isCancellable
                self.progressLabel.text = "\(progress.completedUnitCount) / \(progress.totalUnitCount)"
                self.progressWidth.constant =  floor(self.progressStackView.frame.size.width * CGFloat(progress.fractionCompleted))
                self.view.layoutIfNeeded()

            }
            _ = self.uploadTask?.observe(.failure){ snapshot in
                log.debug("upload failed.")
                self.startButton.isEnabled = true
                self.cancelButton.isEnabled = false
                self.progressWidth.constant = 0
                self.progressLabel.text = nil
                self.view.layoutIfNeeded()
            }
            _ = self.uploadTask?.observe(.success){ snapshot in
                log.debug("upload succeeded.")
                self.startButton.isEnabled = true
                self.cancelButton.isEnabled = false
                self.progressWidth.constant = 0
                self.progressLabel.text = nil
                self.view.layoutIfNeeded()
            }


        }

        picker.dismiss(animated: true){

        }

    }
}
