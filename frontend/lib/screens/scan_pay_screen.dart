import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api_service.dart';
import 'pay_screen.dart';

class ScanPayScreen extends StatefulWidget {
  final String senderUpiId;

  const ScanPayScreen({super.key, required this.senderUpiId});

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen> {
  final MobileScannerController scannerController = MobileScannerController();

  bool isProcessing = false;

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> handleQRCode(String value) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    await scannerController.stop();

    try {
      String identifier = value.trim();

      // Support standard UPI QR format:
      // upi://pay?pa=user@payflow
      if (identifier.startsWith('upi://')) {
        final uri = Uri.tryParse(identifier);

        if (uri != null) {
          final pa = uri.queryParameters['pa'];

          if (pa != null && pa.isNotEmpty) {
            identifier = pa;
          }
        }
      }

      if (identifier.isEmpty) {
        throw Exception('Invalid QR code');
      }

      final result = await ApiService.resolvePayee(identifier);

      if (!mounted) return;

      final payee = result['user'] ?? result['payee'];

      if (payee == null) {
        throw Exception('Payee not found');
      }

      // mounted check is immediately before using context
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              PayScreen(senderUpiId: widget.senderUpiId, receiverData: payee),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      await scannerController.start();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find this UPI account: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text(
          'Scan & Pay',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,

            onDetect: (capture) {
              if (capture.barcodes.isEmpty) {
                return;
              }

              final barcode = capture.barcodes.first;

              final value = barcode.rawValue;

              if (value != null && value.isNotEmpty) {
                handleQRCode(value);
              }
            },
          ),

          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 70,

            child: Column(
              children: [
                const Text(
                  'Scan a UPI QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Point your camera at the QR code',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          if (isProcessing)
            Container(
              color: Colors.black54,

              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
