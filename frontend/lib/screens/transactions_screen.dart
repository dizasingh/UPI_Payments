import 'package:flutter/material.dart';

import '../services/api_service.dart';

class TransactionsScreen extends StatefulWidget {
  final int userId;

  const TransactionsScreen({super.key, required this.userId});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final result = await ApiService.getTransactions(widget.userId);

      if (!mounted) return;

      setState(() {
        transactions = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String transactionName(Map<String, dynamic> transaction) {
    final payerId = transaction['payer_upi_id'];
    final payeeId = transaction['payee_upi_id'];

    if (payerId == widget.userId) {
      return transaction['payee_name']?.toString() ??
          transaction['payee_upi']?.toString() ??
          'Payment';
    }

    if (payeeId == widget.userId) {
      return transaction['payer_name']?.toString() ??
          transaction['payer_upi']?.toString() ??
          'Received';
    }

    return 'Transaction';
  }

  bool isReceived(Map<String, dynamic> transaction) {
    return transaction['payee_upi_id'] == widget.userId;
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return Colors.green;

      case 'FAILED':
        return Colors.red;

      case 'PENDING':
        return Colors.orange;

      case 'REFUNDED':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: const Color(0xFF6C35D9),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
          ? RefreshIndicator(
              onRefresh: loadTransactions,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadTransactions,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = Map<String, dynamic>.from(
                    transactions[index],
                  );

                  final received = isReceived(transaction);

                  final status =
                      transaction['status_name']?.toString() ?? 'UNKNOWN';

                  final amount =
                      double.tryParse(transaction['amount'].toString()) ?? 0;

                  final name = transactionName(transaction);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: received
                              ? Colors.green.withOpacity(0.12)
                              : const Color(0xFFEDE7F9),
                          child: Icon(
                            received
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            color: received
                                ? Colors.green
                                : const Color(0xFF6C35D9),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                transaction['transaction_id']?.toString() ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                transaction['payment_method']?.toString() ??
                                    transaction['method_name']?.toString() ??
                                    'UPI',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                transaction['transaction_time']?.toString() ??
                                    '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${received ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: received ? Colors.green : Colors.black,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(status).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor(status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
