import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'scan_pay_screen.dart';
import 'pay_screen.dart';
import 'transactions_screen.dart';
import 'profile_screen.dart';
import 'my_qr_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final userId = widget.user['user_id'];

      final result = await ApiService.getUser(userId);

      if (!mounted) return;

      setState(() {
        currentUser = result['user'] ?? result;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        currentUser = widget.user;
        isLoading = false;
      });
    }
  }

  Future<void> refreshHome() async {
    await loadUser();
  }

  String get userName {
    return currentUser?['full_name']?.toString() ??
        widget.user['full_name']?.toString() ??
        'User';
  }

  String get upiId {
    return currentUser?['upi_id']?.toString() ??
        widget.user['upi_id']?.toString() ??
        'UPI ID';
  }

  String get bankName {
    return currentUser?['bank_name']?.toString() ??
        widget.user['bank_name']?.toString() ??
        'Bank Account';
  }

  double get balance {
    final value = currentUser?['balance'] ?? widget.user['balance'] ?? 0;

    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF6C35D9),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'UPI Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfileScreen(user: currentUser ?? widget.user),
                ),
              );

              refreshHome();
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: refreshHome,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 8),

              Text(
                'Hello, $userName 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                upiId,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 22),

              // BALANCE CARD
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C35D9), Color(0xFF8B5CF6)],
                  ),

                  borderRadius: BorderRadius.circular(24),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '₹${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance,
                          color: Colors.white70,
                          size: 18,
                        ),

                        const SizedBox(width: 7),

                        Text(
                          bankName,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              // ROW 1
              Row(
                children: [
                  Expanded(
                    child: actionButton(
                      icon: Icons.qr_code_scanner,
                      title: 'Scan & Pay',

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScanPayScreen(senderUpiId: upiId),
                          ),
                        );

                        refreshHome();
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: actionButton(
                      icon: Icons.send_rounded,
                      title: 'Send Money',

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PayScreen(senderUpiId: upiId),
                          ),
                        );

                        refreshHome();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ROW 2
              Row(
                children: [
                  Expanded(
                    child: actionButton(
                      icon: Icons.qr_code,
                      title: 'My QR',

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MyQrScreen(user: currentUser ?? widget.user),
                          ),
                        );

                        refreshHome();
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: actionButton(
                      icon: Icons.receipt_long_outlined,
                      title: 'Transactions',

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionsScreen(
                              userId: widget.user['user_id'],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ROW 3
              Row(
                children: [
                  Expanded(
                    child: actionButton(
                      icon: Icons.person_outline,
                      title: 'Profile',

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(user: currentUser ?? widget.user),
                          ),
                        );

                        refreshHome();
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // BANK ACCOUNT
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,

                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7F9),
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: const Icon(
                        Icons.account_balance,
                        color: Color(0xFF6C35D9),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Linked Bank Account',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            bankName,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: onTap,

      child: Container(
        height: 110,

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, color: const Color(0xFF6C35D9), size: 30),

            const SizedBox(height: 9),

            Text(
              title,
              textAlign: TextAlign.center,

              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
