import 'package:doc_scan_me/interface_select.dart';
import 'package:flutter/foundation.dart';

class ScanMeAutho {
  Future<String?> getPlatformVersion() {
    return FlutterDocScannerPlatform.instance.getPlatformVersion();
  }

  Future<dynamic> getScanDocuments({int page = 4}) {
    return FlutterDocScannerPlatform.instance.getScanDocuments(page);
  }

  Future<dynamic> getScannedDocumentAsImages({int page = 4}) {
    return FlutterDocScannerPlatform.instance.getScannedDocumentAsImages(page);
  }

  Future<dynamic> getScannedDocumentAsPdf({int page = 4}) {
    return FlutterDocScannerPlatform.instance.getScannedDocumentAsPdf(page);
  }

  Future<dynamic> getScanDocumentsUri({int page = 4}) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return FlutterDocScannerPlatform.instance.getScanDocumentsUri(page);
    } else {
      return Future.error(
          "Currently, this feature is supported only on Android Platform");
    }
  }
}
