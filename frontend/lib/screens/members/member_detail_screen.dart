import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_scaffold.dart';

class MemberDetailScreen extends StatefulWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  Map<String, dynamic>? _member;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    try {
      final res = await ApiService.get('/members/${widget.memberId}');
      setState(() {
        _member = res['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        title: 'Member',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final m = _member!;
    return AppScaffold(
      title: 'Member Profile',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFDBEAFE),
              backgroundImage: m['photo_url'] != null ? NetworkImage(m['photo_url']) : null,
              child: m['photo_url'] == null
                  ? Text(
                      '${m['first_name'][0]}${m['last_name'][0]}',
                      style: const TextStyle(fontSize: 24, color: Color(0xFF1E40AF)),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              '${m['first_name']} ${m['last_name']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              m['membership_status'].toString().toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            _InfoCard(
              children: [
                _InfoRow(Icons.email_outlined, 'Email', m['email'] ?? 'Not provided'),
                _InfoRow(Icons.phone_outlined, 'Phone', m['phone'] ?? 'Not provided'),
                _InfoRow(Icons.cake_outlined, 'Birthday', m['date_of_birth'] ?? 'Not provided'),
                _InfoRow(
                  Icons.location_on_outlined,
                  'Address',
                  '${m['address'] ?? ''}, ${m['city'] ?? ''}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              children: [
                _InfoRow(
                  Icons.water_drop_outlined,
                  'Baptized',
                  m['is_baptized'] == true ? 'Yes' : 'No',
                ),
                _InfoRow(
                  Icons.calendar_today_outlined,
                  'Member Since',
                  m['membership_date'] ?? 'N/A',
                ),
                _InfoRow(
                  Icons.emergency_outlined,
                  'Emergency Contact',
                  m['emergency_contact_name'] ?? 'Not provided',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
