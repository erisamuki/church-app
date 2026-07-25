import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/app_scaffold.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _stats;
  List<dynamic>? _upcomingEvents;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final statsRes = await _api.get('/dashboard/stats');
      final eventsRes = await _api.get('/dashboard/upcoming-events');
      setState(() {
        _stats = statsRes.data['data'];
        _upcomingEvents = eventsRes.data['data'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    SizedBox(height: 24.h),
                    _buildSectionTitle('Upcoming Events'),
                    SizedBox(height: 12.h),
                    _buildEventsList(),
                    SizedBox(height: 24.h),
                    _buildSectionTitle('Giving Trends'),
                    SizedBox(height: 12.h),
                    _buildGivingChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final items = [
      _StatItem(
        'Members',
        _stats?['total_members']?.toString() ?? '0',
        Icons.people,
        const Color(0xFF3B82F6),
      ),
      _StatItem(
        'Attendance',
        _stats?['weekly_attendance']?.toString() ?? '0',
        Icons.event_available,
        const Color(0xFF10B981),
      ),
      _StatItem(
        'Monthly Giving',
        '\$${_stats?['monthly_giving']?.toString() ?? '0'}',
        Icons.attach_money,
        const Color(0xFFF59E0B),
      ),
      _StatItem(
        'Volunteers',
        _stats?['weekly_volunteers']?.toString() ?? '0',
        Icons.volunteer_activism,
        const Color(0xFF8B5CF6),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.3,
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }

  Widget _buildEventsList() {
    if (_upcomingEvents == null || _upcomingEvents!.isEmpty) {
      return const Card(child: ListTile(title: Text('No upcoming events')));
    }
    return Column(
      children: _upcomingEvents!.map((e) {
        final date = DateTime.parse(e['start_datetime']);
        return Card(
          margin: EdgeInsets.only(bottom: 10.h),
          child: ListTile(
            leading: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                  Text(
                    '${date.month}',
                    style: TextStyle(fontSize: 10.sp, color: const Color(0xFF1E40AF)),
                  ),
                ],
              ),
            ),
            title: Text(
              e['title'],
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
            ),
            subtitle: Text(
              '${e['location'] ?? 'TBD'} • ${e['registered_count']} registered',
              style: TextStyle(fontSize: 12.sp),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/events/${e['id']}'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGivingChart() {
    return Container(
      height: 200.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][value.toInt() % 12],
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            7,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: [65, 72, 58, 80, 68, 85, 75][i].toDouble(),
                  color: const Color(0xFF3B82F6),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
    );
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label,
                style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
              ),
              Icon(item.icon, size: 18.sp, color: item.color),
            ],
          ),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
