import 'package:flutter/material.dart';
import 'dart:async';
import '../models/member.dart';
import '../services/api_service.dart';

class LogOfferingScreen extends StatefulWidget {
  const LogOfferingScreen({super.key});

  @override
  State<LogOfferingScreen> createState() => _LogOfferingScreenState();
}

class _LogOfferingScreenState extends State<LogOfferingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _memberSearchController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  String _paymentMethod = 'cash';
  DateTime _donationDate = DateTime.now();

  Member? _selectedMember;
  List<Member> _memberResults = [];
  bool _searchingMembers = false;
  Timer? _debounce;

  bool _isSaving = false;
  bool _loadingCategories = true;
  String? _errorMessage;

  final List<String> _paymentMethods = ['cash', 'check', 'online', 'credit_card', 'bank_transfer'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _memberSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await ApiService.get('/giving/categories');
      final List<dynamic> data = res['data'] ?? res;
      setState(() {
        _categories = data.cast<Map<String, dynamic>>();
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first['id'].toString();
        }
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() => _loadingCategories = false);
    }
  }

  void _onMemberSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _memberResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searchingMembers = true);
      try {
        final res =
            await ApiService.get('/members', queryParameters: {'search': query, 'limit': 8});
        final List<dynamic> data = res['data'] ?? res;
        setState(() {
          _memberResults = data.map((m) => Member.fromJson(m)).toList();
          _searchingMembers = false;
        });
      } catch (e) {
        setState(() => _searchingMembers = false);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _donationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _donationDate = picked);
    }
  }

  Future<void> _saveDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select a giving category.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final body = {
        'member_id': _selectedMember?.id,
        'category_id': _selectedCategoryId,
        'amount': double.tryParse(_amountController.text.trim()) ?? 0,
        'payment_method': _paymentMethod,
        'donation_date': _donationDate.toIso8601String().split('T').first,
        'notes': _notesController.text.trim(),
      };

      final res = await ApiService.post('/giving', body);

      if (res['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to log offering.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Check your connection.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Log Offering',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
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

                      // Member search
                      const Text('Member (optional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      if (_selectedMember != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedMember!.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _selectedMember = null;
                                    _memberSearchController.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _memberSearchController,
                              onChanged: _onMemberSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Search member by name...',
                                border: const OutlineInputBorder(),
                                suffixIcon: _searchingMembers
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : const Icon(Icons.search),
                              ),
                            ),
                            if (_memberResults.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: _memberResults.map((m) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(m.fullName),
                                      subtitle: Text(m.email ?? m.phone ?? ''),
                                      onTap: () {
                                        setState(() {
                                          _selectedMember = m;
                                          _memberResults = [];
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      const Text('Giving Category',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      _loadingCategories
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: LinearProgressIndicator(),
                            )
                          : DropdownButtonFormField<String>(
                              initialValue: _selectedCategoryId,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                        value: c['id'].toString(),
                                        child: Text(c['name'] ?? ''),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedCategoryId = v),
                            ),
                      const SizedBox(height: 16),

                      const Text('Amount (UGX)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 50000',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Amount is required';
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Payment Method',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _paymentMethod,
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                  items: _paymentMethods
                                      .map((m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(
                                              m
                                                  .split('_')
                                                  .map((w) => w[0].toUpperCase() + w.substring(1))
                                                  .join(' '),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _paymentMethod = v);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(border: OutlineInputBorder()),
                                    child: Text(
                                      '${_donationDate.day}/${_donationDate.month}/${_donationDate.year}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text('Notes (optional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Any additional notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveDonation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                              : const Text('Save Offering',
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
