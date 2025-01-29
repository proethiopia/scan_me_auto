import Flutter
import UIKit
import Vision
import VisionKit
import PDFKit

@available(iOS 13.0, *)
public class swiftscan_auto: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
    var resultChannel: FlutterResult?
    var presentingController: VNDocumentCameraViewController?
    var currentMethod: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_doc_scanner", binaryMessenger: registrar.messenger())
        let instance = swiftscan_auto()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getScanDocuments" || call.method == "getScannedDocumentAsImages" || call.method == "getScannedDocumentAsPdf" {
            let presentedVC: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
            self.resultChannel = result
            self.currentMethod = call.method
            self.presentingController = VNDocumentCameraViewController()
            self.presentingController!.delegate = self
            presentedVC?.present(self.presentingController!, animated: true)
        } else if call.method == "cropImage" {
            if let args = call.arguments as? [String: Any],
               let imagePath = args["imagePath"] as? String {
                self.resultChannel = result
                self.cropImage(imagePath: imagePath)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for cropImage", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
            return
        }
    }

    private func cropImage(imagePath: String) {
        guard let image = UIImage(contentsOfFile: imagePath) else {
            resultChannel?(FlutterError(code: "IMAGE_LOAD_ERROR", message: "Failed to load image", details: nil))
            return
        }

        guard let cgImage = image.cgImage else {
            resultChannel?(FlutterError(code: "IMAGE_CONVERSION_ERROR", message: "Failed to convert image to CGImage", details: nil))
            return
        }

        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                self.resultChannel?(FlutterError(code: "CROP_ERROR", message: "Failed to detect rectangles", details: error.localizedDescription))
                return
            }

            if let results = request.results as? [VNRectangleObservation], let firstRect = results.first {
                let croppedImage = self.crop(image: image, rectangle: firstRect)
                if let croppedImage = croppedImage {
                    let croppedImagePath = self.saveImage(image: croppedImage)
                    self.resultChannel?(croppedImagePath)
                } else {
                    self.resultChannel?(FlutterError(code: "CROP_ERROR", message: "Failed to crop image", details: nil))
                }
            } else {
                self.resultChannel?(FlutterError(code: "NO_RECTANGLE_FOUND", message: "No rectangle detected", details: nil))
            }
        }

        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.3
        request.minimumSize = 0.1
        request.maximumObservations = 1

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            resultChannel?(FlutterError(code: "CROP_ERROR", message: "Failed to perform rectangle detection", details: error.localizedDescription))
        }
    }

    private func crop(image: UIImage, rectangle: VNRectangleObservation) -> UIImage? {
        let transform = CGAffineTransform.identity
            .scaledBy(x: image.size.width, y: -image.size.height)
            .translatedBy(x: 0, y: -1)

        let bounds = rectangle.boundingBox.applying(transform)
        guard let cgImage = image.cgImage?.cropping(to: bounds) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func saveImage(image: UIImage) -> String {
        let tempDirPath = getDocumentsDirectory()
        let currentDateTime = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        let formattedDate = df.string(from: currentDateTime)
        let url = tempDirPath.appendingPathComponent("\(formattedDate)-cropped.png")
        try? image.pngData()?.write(to: url)
        return url.path
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        if currentMethod == "getScanDocuments" {
            saveScannedImages(scan: scan)
        } else if currentMethod == "getScannedDocumentAsImages" {
            saveScannedImages(scan: scan)
        } else if currentMethod == "getScannedDocumentAsPdf" {
            saveScannedPdf(scan: scan)
        }
        presentingController?.dismiss(animated: true)
    }

    private func saveScannedImages(scan: VNDocumentCameraScan) {
        let tempDirPath = getDocumentsDirectory()
        let currentDateTime = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        let formattedDate = df.string(from: currentDateTime)
        var filenames: [String] = []
        for i in 0 ..< scan.pageCount {
            let page = scan.imageOfPage(at: i)
            let url = tempDirPath.appendingPathComponent(formattedDate + "-\(i).png")
            try? page.pngData()?.write(to: url)
            filenames.append(url.path)
        }
        resultChannel?(filenames)
    }

    private func saveScannedPdf(scan: VNDocumentCameraScan) {
        let tempDirPath = getDocumentsDirectory()
        let currentDateTime = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        let formattedDate = df.string(from: currentDateTime)
        let pdfFilePath = tempDirPath.appendingPathComponent("\(formattedDate).pdf")

        let pdfDocument = PDFDocument()
        for i in 0 ..< scan.pageCount {
            let pageImage = scan.imageOfPage(at: i)
            if let pdfPage = PDFPage(image: pageImage) {
                pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
            }
        }

        do {
            try pdfDocument.write(to: pdfFilePath)
            resultChannel?(pdfFilePath.path)
        } catch {
            resultChannel?(FlutterError(code: "PDF_CREATION_ERROR", message: "Failed to create PDF", details: error.localizedDescription))
        }
    }

    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        resultChannel?(nil)
        presentingController?.dismiss(animated: true)
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        resultChannel?(FlutterError(code: "SCAN_ERROR", message: "Failed to scan documents", details: error.localizedDescription))
        presentingController?.dismiss(animated: true)
    }
}
