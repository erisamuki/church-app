import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/app_scaffold.dart';
import 'add_event_screen.dart';
import 'log_offering_screen.dart';
import '../widgets/notifications_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  int _totalMembers = 0;
  int _sundayAttendance = 0;
  int _upcomingEvents = 0;
  String _monthlyGiving = 'UGX 0';

  List<Member> _recentMembers = [];
  ChurchEvent? _nextEvent;

  final List<Map<String, dynamic>> _givingData = [
    {'month': 'Feb', 'amount': 18.5},
    {'month': 'Mar', 'amount': 21.0},
    {'month': 'Apr', 'amount': 19.8},
    {'month': 'May', 'amount': 22.3},
    {'month': 'Jun', 'amount': 20.7},
    {'month': 'Jul', 'amount': 24.5},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final baseUrl = auth.baseUrl;
      final headers = auth.authHeaders;

      await Future.wait([
        _fetchStats(baseUrl, headers),
        _fetchRecentMembers(baseUrl, headers),
        _fetchNextEvent(baseUrl, headers),
      ]);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStats(String baseUrl, Map<String, String> headers) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/stats'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? json;
        setState(() {
          _totalMembers = data['total_members'] ?? 0;
          _sundayAttendance = data['weekly_attendance'] ?? 0;
          final giving = (data['monthly_giving'] as num?)?.toDouble() ?? 0;
          _monthlyGiving = 'UGX ${(giving / 1000000).toStringAsFixed(1)}M';
        });
      }
    } catch (e) {
      // leave zeros on genuine failure
    }
  }

  Future<void> _fetchRecentMembers(String baseUrl, Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/members?limit=5&sort=joined_desc'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? json;
        setState(() {
          _recentMembers = data.map((e) => Member.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // leave empty on genuine failure
    }
  }

  Future<void> _fetchNextEvent(String baseUrl, Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events?limit=1&status=upcoming&sort=start_date_asc'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? json;
        if (data.isNotEmpty) {
          setState(() => _nextEvent = ChurchEvent.fromJson(data.first));
        }
      }
    } catch (e) {
      // leave null on genuine failure
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        drawer: AppDrawer(),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BCCTheme.orange),
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          const _SearchBarAction(),
          const NotificationsBell(),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: BCCTheme.orange,
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) => Text(
                  auth.user?.initials ?? 'PS',
                  style: const TextStyle(
                    color: BCCTheme.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: BCCTheme.orange,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(context),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildRecentMembersCard(context)),
                        const SizedBox(width: 20),
                        Expanded(flex: 1, child: _buildRightColumn(context)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildRecentMembersCard(context),
                      const SizedBox(height: 20),
                      _buildRightColumn(context),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final stats = [
      _StatData('Total Members', _totalMembers.toString(), '+12% from last month',
          Icons.people_outline, true),
      _StatData('Sunday Attendance', _sundayAttendance.toString(), '+5% from last week',
          Icons.church_outlined, true),
      _StatData('Upcoming Events', _upcomingEvents.toString(), '3 happening this week',
          Icons.event_outlined, false),
      _StatData(
          'Monthly Giving', _monthlyGiving, '+18% from last month', Icons.payments_outlined, true),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 768
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: crossCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          children: stats.map((s) => _StatCard(stat: s)).toList(),
        );
      },
    );
  }

  Widget _buildRecentMembersCard(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Members',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
                ),
                TextButton(
                  onPressed: () => context.push('/members'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _recentMembers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No members found')),
                  )
                : Column(
                    children: _recentMembers.map((m) => _MemberRow(member: m)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
                const SizedBox(height: 12),
                _QuickActionButton(
                  icon: Icons.fact_check_outlined,
                  label: 'Record Attendance',
                  onTap: () => context.push('/checkin'),
                ),
                const SizedBox(height: 8),
                _QuickActionButton(
                  icon: Icons.person_add_outlined,
                  label: 'Add New Member',
                  onTap: () async {
                    final added = await context.push('/members/new');
                    if (added == true) _loadDashboardData();
                  },
                ),
                const SizedBox(height: 8),
                _QuickActionButton(
                  icon: Icons.payments_outlined,
                  label: 'Log Offering',
                  onTap: () async {
                    final saved = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LogOfferingScreen()),
                    );
                    if (saved == true) _loadDashboardData();
                  },
                ),
                const SizedBox(height: 8),
                _QuickActionButton(
                  icon: Icons.calendar_today_outlined,
                  label: 'Schedule Event',
                  onTap: () async {
                    final created = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddEventScreen()),
                    );
                    if (created == true) _loadDashboardData();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Event',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
                const SizedBox(height: 12),
                if (_nextEvent != null) _buildEventMini(context, _nextEvent!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Giving (UGX M)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
                const SizedBox(height: 20),
                SizedBox(height: 160, child: _SimpleBarChart(data: _givingData)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventMini(BuildContext context, ChurchEvent event) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = onSurface.withValues(alpha: 0.6);

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: BCCTheme.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${event.startDate.day}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: BCCTheme.orangeDark,
                ),
              ),
              Text(
                _monthName(event.startDate.month),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: BCCTheme.orangeDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '${event.dayName}, ${_formatTime(event.startDate)} - ${event.location}',
                style: TextStyle(fontSize: 12, color: secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// A tappable search bar that adapts to the current theme
class _SearchBarAction extends StatelessWidget {
  const _SearchBarAction();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push('/search'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(
              'Search members, events...',
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== STAT CARD ====================

class _StatData {
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final bool isPositive;

  _StatData(this.label, this.value, this.change, this.icon, this.isPositive);
}

class _StatCard extends StatelessWidget {
  final _StatData stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final secondary = cs.onSurface.withValues(alpha: 0.6);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stat.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: secondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (stat.isPositive)
                  const Icon(Icons.trending_up, size: 14, color: BCCTheme.success),
                Text(
                  stat.change,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: stat.isPositive ? BCCTheme.success : secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MEMBER ROW ====================

class _MemberRow extends StatelessWidget {
  final Member member;

  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color tagColor;
    Color tagBg;
    String statusText;

    switch (member.membershipStatus) {
      case 'active':
        tagColor = BCCTheme.success;
        tagBg = BCCTheme.successBg;
        statusText = 'Active';
        break;
      case 'new_convert':
      case 'new':
        tagColor = BCCTheme.orangeDark;
        tagBg = BCCTheme.orangeLight;
        statusText = 'New';
        break;
      default:
        tagColor = cs.onSurface.withValues(alpha: 0.6);
        tagBg = cs.surfaceContainerHighest;
        statusText = 'Visitor';
    }

    return InkWell(
      onTap: () => context.push('/members/${member.id}'),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor:
                  member.membershipStatus == 'active' ? BCCTheme.orange : BCCTheme.black,
              child: Text(
                member.initials,
                style: const TextStyle(
                  color: BCCTheme.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
                  ),
                  Text(
                    member.ministryLabel ?? 'General Member',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(6)),
              child: Text(
                statusText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tagColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== QUICK ACTION BUTTON ====================

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurface),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SIMPLE BAR CHART ====================

class _SimpleBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _SimpleBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final maxValue =
        data.map((e) => (e['amount'] as num).toDouble()).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final amount = (item['amount'] as num).toDouble();
        final heightFraction = amount / maxValue;
        final isHighest = amount == maxValue;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${amount.toStringAsFixed(1)}M',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isHighest ? BCCTheme.orangeDark : secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 100 * heightFraction,
                  decoration: BoxDecoration(
                    color: isHighest ? BCCTheme.orange : BCCTheme.orange.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['month'] as String,
                  style: TextStyle(fontSize: 11, color: secondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
