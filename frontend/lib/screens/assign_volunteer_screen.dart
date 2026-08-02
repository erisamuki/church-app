import 'dart:async';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/member.dart';
import '../services/api_service.dart';

class AssignVolunteerScreen extends StatefulWidget {
  final ChurchEvent event;
  const AssignVolunteerScreen({super.key, required this.event});

  @override
  State<AssignVolunteerScreen> createState() => _AssignVolunteerScreenState();
}

class _AssignVolunteerScreenState extends State<AssignVolunteerScreen> {
  final _memberSearchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _roles = [];
  String? _selectedRoleId;
  bool _loadingRoles = true;

  Member? _selectedMember;
  List<Member> _memberResults = [];
  bool _searchingMembers = false;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _memberSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final res = await ApiService.get('/volunteers/roles');
      final List<dynamic> data = res['data'] ?? res;
      setState(() {
        _roles = data.cast<Map<String, dynamic>>();
        if (_roles.isNotEmpty) _selectedRoleId = _roles.first['id'].toString();
        _loadingRoles = false;
      });
    } catch (e) {
      setState(() => _loadingRoles = false);
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

  Future<void> _saveAssignment() async {
    if (_selectedMember == null) {
      setState(() => _errorMessage = 'Please select a member.');
      return;
    }
    if (_selectedRoleId == null) {
      setState(() => _errorMessage = 'Please select a role.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.post('/volunteers/assignments', {
        'event_id': widget.event.id,
        'member_id': _selectedMember!.id,
        'role_id': _selectedRoleId,
      });

      if (res['success'] == true) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Failed to assign volunteer.');
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
        title: Text('Assign Volunteer - ${widget.event.title}'),
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
                    const Text('Member',
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
                    const Text('Volunteer Role',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    _loadingRoles
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedRoleId,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: _roles
                                .map((r) => DropdownMenuItem(
                                      value: r['id'].toString(),
                                      child: Text('${r['name']} (${r['department'] ?? ''})'),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedRoleId = v),
                          ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAssignment,
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
                            : const Text('Assign Volunteer',
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
    );
  }
}
