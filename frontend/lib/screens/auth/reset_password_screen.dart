import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _success = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.post('/auth/reset-password', {
        'email': widget.email,
        'code': _codeController.text.trim(),
        'new_password': _newPasswordController.text.trim(),
      });

      if (res['success'] == true) {
        setState(() => _success = true);
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Something went wrong.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Check your connection.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Password reset successfully',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter reset code',
                    style:
                        TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit code to ${widget.email}. Enter it below along with your new password.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade700),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade300, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Reset Code', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: TextStyle(color: Colors.grey.shade700, letterSpacing: 6),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length != 6) return 'Enter the 6-digit code';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('New Password', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'At least 8 characters',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Confirm Password',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Re-enter new password',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v != _newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Reset Password',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
