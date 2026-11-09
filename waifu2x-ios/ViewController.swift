//
//  ViewController.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import UIKit
import CoreML
import CoreServices
import AVFoundation
import waifu2x
import BBMetalImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var inputview: UIImageView!
    @IBOutlet weak var outputview: UIImageView!
    @IBOutlet weak var pickBtn: UIButton!
    @IBOutlet weak var processBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var progress: UILabel!

    var inputImage: UIImage! {
        didSet {
            inputview.image = inputImage
            debugPrint("Size: \(inputImage.size.width) x \(inputImage.size.height)")
        }
    }

    var videoSource: BBMetalVideoSource!
    var videoWriter: BBMetalVideoWriter!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    let pickercontroller = UIImagePickerController()

    @IBAction func onPick(_ sender: Any) {
        pickercontroller.delegate = self
        pickercontroller.sourceType = .photoLibrary
        present(pickercontroller, animated: true, completion: nil)
    }

    @IBAction func onProcess(_ sender: Any) {
        guard inputImage != nil else {
            return
        }
        // Reference: https://stackoverflow.com/questions/24755558/measure-elapsed-time-in-swift
        let start = DispatchTime.now()
        let background = DispatchQueue(label: "background")
        progress.text = "Scaling..."
        pickBtn.isEnabled = false
        processBtn.isEnabled = false
        saveBtn.isEnabled = false
        background.async {
            let outimage = Waifu2x.run(self.inputImage, model: Model.anime_noise1_scale2x)?.reload()
            let end = DispatchTime.now()
            let nanotime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanotime) / 1_000_000_000
            DispatchQueue.main.async {
                self.progress.text = "Time elapsed: \(timeInterval) second"
                self.outputview.image = outimage
                self.pickBtn.isEnabled = true
                self.processBtn.isEnabled = true
                self.saveBtn.isEnabled = true
            }
        }
    }

    @IBAction func onSave(_ sender: Any) {
        guard outputview.image != nil else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(outputview.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        inputImage = info[.originalImage] as? UIImage
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

}

extension ViewController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// Class for reading video?
extension ViewController: BBMetalVideoSourceDelegate {
    func videoSource(_ videoSource: BBMetalVideoSource, didOutputSampleBuffer sampleBuffer: CMSampleBuffer) {

    }

}

// Class for rendering filter in video file?
class WaifuFilter: BBMetalVideoWriter {
    public init(_ videoInput: BBMetalVideoWriter) {
        fatalError("init(_:) has not been implemented")
    }

    override func progress(_ duration: CMTime) {
        debugPrint("progress")
    }
}

extension ViewController {
    @available(iOS 8.0, *)
    func pickFilter?() -> BBMetalBaseFilter? {
        var filter: BBMetalBaseFilter?
        guard let videoInput = videoSource else {
            return nil
        }
        let size = videoInput.texture?.size ?? CGSize.zero
        let bgColor = UIColor.black
        if let imageUrl = URL(string: "https://www.google.com") {
            let network: BBMetalBaseFilter? = BBMetalImage(url: imageUrl)
            filter = network
        }
        let bgFilter = BBMetalImage()
        bgFilter.backgroundColor = bgColor
        let frameSize = BBMetalIntSize(width: Int(size.width) * filter!.scaleFactor,
                                       height: Int(size.height) * filter!.scaleFactor)
        let output = frameSize
        debugPrint(output)
        filter = bgFilter
        return filter
    }
}
