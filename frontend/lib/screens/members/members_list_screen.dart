import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final _api = ApiService();
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
      final res = await _api.get(
        '/members',
        queryParameters: {'search': _search.isEmpty ? null : _search, 'page': _page, 'limit': 20},
      );
      setState(() {
        _members = (res.data['data'] as List).map((m) => Member.fromJson(m)).toList();
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
            padding: EdgeInsets.all(16.w),
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
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDBEAFE),
                          backgroundImage: m.photoUrl != null ? NetworkImage(m.photoUrl!) : null,
                          child: m.photoUrl == null
                              ? Text(m.initials, style: const TextStyle(color: Color(0xFF1E40AF)))
                              : null,
                        ),
                        title: Text(
                          m.fullName,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
                        ),
                        subtitle: Text(
                          m.email ?? m.phone ?? 'No contact info',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: m.membershipStatus == 'active'
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            m.membershipStatus,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: m.membershipStatus == 'active'
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF64748B),
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
