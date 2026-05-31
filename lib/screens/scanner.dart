import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<StatefulWidget> createState() => _Scanner();
}

class _Scanner extends State<Scanner> {
  bool _useTorch = false;
  bool _hasScanned = false;

  late final MobileScannerController controller;

  void _handleBarcode(BarcodeCapture barcodes) {
    if (_hasScanned) return;

    final Barcode? barcode = barcodes.barcodes.firstOrNull;

    if (barcode != null) {
      _hasScanned = true;
      controller.stop();
      Navigator.of(context).pop(barcode.rawValue);
    }
  }

  @override
  void initState() {
    super.initState();

    controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      torchEnabled: false,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (result) => _handleBarcode(result),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: IconButton.filled(
                onPressed: () {
                  setState(() {
                    _useTorch = !_useTorch;
                  });
                  controller.toggleTorch();
                },
                icon: _useTorch
                    ? Icon(Icons.flashlight_off)
                    : Icon(Icons.flashlight_on),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
