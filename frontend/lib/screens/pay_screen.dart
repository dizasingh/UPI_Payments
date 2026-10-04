import 'package:flutter/material.dart';

import '../services/api_service.dart';

class PayScreen extends StatefulWidget {
  final String senderUpiId;
  final Map<String, dynamic>? receiverData;

  const PayScreen({super.key, required this.senderUpiId, this.receiverData});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  final receiverController = TextEditingController();
  final amountController = TextEditingController();
  final pinController = TextEditingController();
  final remarksController = TextEditingController();

  bool isLoading = false;
  bool obscurePin = true;

  Map<String, dynamic>? payee;
  String selectedPaymentMethod = 'UPI ID';

  @override
  void initState() {
    super.initState();

    if (widget.receiverData != null) {
      payee = widget.receiverData;
    }
  }

  Future<void> findPayee() async {
    final identifier = receiverController.text.trim();

    if (identifier.isEmpty) {
      showMessage('Enter UPI ID or mobile number');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.resolvePayee(identifier);

      if (!mounted) return;

      setState(() {
        payee = result['user'] ?? result['payee'];
      });

      if (payee == null) {
        showMessage('Payee not found');
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> makePayment() async {
    if (payee == null) {
      showMessage('Please select a payee');
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      showMessage('Enter a valid amount');
      return;
    }

    final pin = pinController.text.trim();

    // 6-DIGIT PIN
    if (pin.length != 6) {
      showMessage('Enter your 6-digit UPI PIN');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.makePayment(
        sender: widget.senderUpiId,
        receiver: payee!['upi_id'].toString(),
        amount: amount,
        pin: pin,
        paymentMethod: selectedPaymentMethod,
        remarks: remarksController.text.trim(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Payment Successful',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${amount.toStringAsFixed(2)} sent to '
                  '${payee!['full_name'] ?? payee!['upi_id']}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (result['transaction_id'] != null)
                  Text(
                    'Transaction ID: ${result['transaction_id']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    receiverController.dispose();
    amountController.dispose();
    pinController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      appBar: AppBar(
        title: const Text('Send Money'),
        backgroundColor: const Color(0xFF6C35D9),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Money',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            const Text(
              'Pay using UPI ID or mobile number',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            const Text(
              'Payee',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: receiverController,
                    decoration: InputDecoration(
                      hintText: 'UPI ID / Mobile number',
                      prefixIcon: const Icon(Icons.person_search_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => findPayee(),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : findPayee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C35D9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (payee != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFEDE7F9),
                      child: Text(
                        (payee!['full_name'] ?? payee!['upi_id'] ?? 'U')
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF6C35D9),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payee!['full_name']?.toString() ?? 'Unknown user',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payee!['upi_id']?.toString() ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.verified, color: Colors.green),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            const Text(
              'Amount',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '₹ 0.00',
                prefixIcon: const Icon(Icons.currency_rupee),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: selectedPaymentMethod,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.payment_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'UPI ID', child: Text('UPI ID')),
                DropdownMenuItem(
                  value: 'Mobile Number',
                  child: Text('Mobile Number'),
                ),
                DropdownMenuItem(value: 'QR Code', child: Text('QR Code')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedPaymentMethod = value;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Remarks (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: remarksController,
              decoration: InputDecoration(
                hintText: 'Add a note',
                prefixIcon: const Icon(Icons.notes_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'UPI PIN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,

              // 6-DIGIT PIN
              maxLength: 6,

              obscureText: obscurePin,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                counterText: '',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePin = !obscurePin;
                    });
                  },
                  icon: Icon(
                    obscurePin
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : makePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C35D9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
