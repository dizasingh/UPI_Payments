import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final upiController = TextEditingController();
  final pinController = TextEditingController();

  List<dynamic> banks = [];
  List<dynamic> psps = [];

  int? selectedBankId;
  int? selectedPspId;

  bool loading = false;
  bool loadingData = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool obscurePin = true;

  @override
  void initState() {
    super.initState();
    loadBankAndPspData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    upiController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> loadBankAndPspData() async {
    try {
      final bankData = await ApiService.getBanks();
      final pspData = await ApiService.getPsps();

      if (!mounted) return;

      setState(() {
        banks = bankData;
        psps = pspData;
        loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingData = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load bank/PSP data: $e')),
      );
    }
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedBankId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a bank')));
      return;
    }

    if (selectedPspId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a PSP')));
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result = await ApiService.register(
        fullName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        bankId: selectedBankId!,
        pspId: selectedPspId!,
        upiId: upiController.text.trim(),
        upiPin: pinController.text.trim(),
        initialBalance: 0,
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Account Created'),
              content: const Text(
                'Your UPI account has been created successfully.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Registration failed',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  InputDecoration fieldDecoration({
    required IconData icon,
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0ECFA),
        elevation: 0,
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: loadingData
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C35D9)),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: fieldDecoration(
                          icon: Icons.person_outline,
                          hint: 'Full Name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your full name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: fieldDecoration(
                          icon: Icons.phone_outlined,
                          hint: 'Phone Number',
                        ).copyWith(counterText: ''),
                        validator: (value) {
                          if (value == null || value.trim().length != 10) {
                            return 'Enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: fieldDecoration(
                          icon: Icons.email_outlined,
                          hint: 'Email',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email';
                          }

                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: fieldDecoration(
                          icon: Icons.lock_outline,
                          hint: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a password';
                          }

                          if (value.length < 6) {
                            return 'Password must contain at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        decoration: fieldDecoration(
                          icon: Icons.lock_outline,
                          hint: 'Confirm Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password';
                          }

                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Bank Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<int>(
                        initialValue: selectedBankId,
                        isExpanded: true,

                        // THIS MAKES THE DROPDOWN MENU SCROLLABLE
                        menuMaxHeight: 300,

                        decoration: fieldDecoration(
                          icon: Icons.account_balance_outlined,
                          hint: 'Select bank',
                        ),
                        items: banks.map<DropdownMenuItem<int>>((bank) {
                          return DropdownMenuItem<int>(
                            value: bank['bank_id'],
                            child: Text(
                              bank['bank_name'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBankId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<int>(
                        initialValue: selectedPspId,
                        isExpanded: true,

                        // THIS MAKES THE PSP DROPDOWN SCROLLABLE
                        menuMaxHeight: 300,

                        decoration: fieldDecoration(
                          icon: Icons.account_balance_wallet_outlined,
                          hint: 'Select PSP',
                        ),
                        items: psps.map<DropdownMenuItem<int>>((psp) {
                          return DropdownMenuItem<int>(
                            value: psp['psp_id'],
                            child: Text(
                              psp['psp_name'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPspId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'UPI Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: upiController,
                        decoration: fieldDecoration(
                          icon: Icons.alternate_email,
                          hint: 'UPI ID',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your UPI ID';
                          }

                          if (!value.contains('@')) {
                            return 'Enter a valid UPI ID';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: obscurePin,
                        decoration: fieldDecoration(
                          icon: Icons.pin_outlined,
                          hint: 'UPI PIN',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePin
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePin = !obscurePin;
                              });
                            },
                          ),
                        ).copyWith(counterText: ''),
                        validator: (value) {
                          if (value == null || value.length != 6) {
                            return 'UPI PIN must be 6 digits';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: loading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C35D9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
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
              ),
            ),
    );
  }
}
