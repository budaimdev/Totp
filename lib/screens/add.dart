import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Add extends StatefulWidget {
  const Add({super.key});

  @override
  State<StatefulWidget> createState() => _Add();

}

class _Add extends State {
  bool _useTorch = false;
  Barcode? _barcode;

  late final MobileScannerController controller;

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }

    AlertDialog(
      content: Text("${_barcode?.rawValue}"),
    );
  }


  @override
  void initState() {
    super.initState();

    controller = MobileScannerController(
        formats: [BarcodeFormat.qrCode],
        torchEnabled: _useTorch,
        autoStart: true
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
              onDetect: (result) =>
              {
                _handleBarcode(result)
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: IconButton.filled(
                    onPressed: () =>
                    {
                      setState(() {
                        _useTorch = !_useTorch;
                      })
                    },
                    icon: _useTorch ? Icon(Icons.flashlight_off) : Icon(
                        Icons.flashlight_on)
                ),
              ),
            )
          ]
      ),
    );
  }

}
