import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/member.dart';
import '../../services/api_service.dart';
import '../../widgets/app_scaffold.dart';
import 'add_member_screen.dart';

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
    setState(() => _loading = true);
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
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Members',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMemberScreen()),
            );
            if (added == true) _loadMembers();
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: Column(
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
                  : _members.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('No members found')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            final m = _members[index];
                            final avatarUrl = m.avatarUrl;
                            final isActive = m.membershipStatus == 'active';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFDBEAFE),
                                  backgroundImage:
                                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                  child: avatarUrl == null
                                      ? Text(m.initials,
                                          style: const TextStyle(
                                              color: Color(0xFF1E40AF),
                                              fontWeight: FontWeight.w600))
                                      : null,
                                ),
                                title: Text(
                                  m.fullName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: cs.onSurface),
                                ),
                                subtitle: Text(
                                  m.email ?? m.phone ?? 'No contact info',
                                  style: TextStyle(
                                      fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                                        : cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive
                                          ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                                          : cs.outline,
                                    ),
                                  ),
                                  child: Text(
                                    m.membershipStatus,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? const Color(0xFF16A34A)
                                          : cs.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                                onTap: () => context.push('/members/${m.id}'),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
