import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddMinisterScreen extends StatefulWidget {
  const AddMinisterScreen({super.key});

  @override
  State<AddMinisterScreen> createState() => _AddMinisterScreenState();
}

class _AddMinisterScreenState extends State<AddMinisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final body = {
        'full_name': _nameController.text.trim(),
        'title': _titleController.text.trim(),
        'department': _departmentController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };

      final res = await ApiService.post('/ministers', body);

      if (res['success'] == true) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Failed to add leader.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Leader'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('Full Name',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Samuel Johnson',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Title',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Senior Pastor, Youth Minister',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Department (optional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Youth Ministry, Worship',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Bio (optional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Short bio',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Phone (optional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      const Text('Email (optional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
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
                              : const Text('Add Leader',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
