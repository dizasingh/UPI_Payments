import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyQrScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const MyQrScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final String name = user['full_name']?.toString() ?? 'User';

    final String upiId = user['upi_id']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text(
          'My QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 25),

              const Text(
                'Receive Money',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                'Show this QR code to receive money',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),

              const SizedBox(height: 30),

              // QR CODE
              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: QrImageView(
                  data: upiId,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // USER NAME
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // UPI ID
              Text(
                upiId,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 30),

              // INFORMATION BOX
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),

                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(Icons.info_outline, color: Colors.deepPurple),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'This QR code represents your UPI ID. '
                        'Another user can scan it to make a payment.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
