import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/member.dart';
import '../../services/api_service.dart';
import '../../widgets/app_scaffold.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  List<Member> _members = [];
  bool _loading = true;
  String _search = '';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final res = await ApiService.get(
        '/members',
        queryParameters: {'search': _search.isEmpty ? null : _search, 'page': _page, 'limit': 20},
      );
      final payload = res['data'];
      setState(() {
        _members =
            (payload as List).map((m) => Member.fromJson(m as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Members',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODO: Add member bottom sheet or screen
          },
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) {
                _search = v;
                _page = 1;
                _loadMembers();
              },
              decoration: const InputDecoration(
                hintText: 'Search members...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final m = _members[index];
                      final avatarUrl = m.avatarUrl;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDBEAFE),
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null
                              ? Text(m.initials, style: const TextStyle(color: Color(0xFF1E40AF)))
                              : null,
                        ),
                        title: Text(
                          m.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          m.email ?? m.phone ?? 'No contact info',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: m.membershipStatus == 'active'
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.membershipStatus,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () => context.go('/members/${m.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

