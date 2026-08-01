import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import 'log_offering_screen.dart';

class GivingScreen extends StatefulWidget {
  const GivingScreen({super.key});

  @override
  State<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends State<GivingScreen> {
  List<Map<String, dynamic>> _donations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/giving', queryParameters: {'limit': 50});
      final List<dynamic> data = res['data'] ?? res;
      setState(() {
        _donations = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatAmount(dynamic amount) {
    final n = (amount is num) ? amount : num.tryParse(amount.toString()) ?? 0;
    return 'UGX ${n.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Giving',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final saved = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LogOfferingScreen()),
            );
            if (saved == true) {
              _loadDonations();
            }
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadDonations,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _donations.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No donations recorded yet')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _donations.length,
                    itemBuilder: (context, index) {
                      final d = _donations[index];
                      final categoryColor = d['color'] != null
                          ? Color(int.parse((d['color'] as String).replaceFirst('#', '0xFF')))
                          : const Color(0xFF64748B);
                      final memberName = (d['first_name'] != null)
                          ? '${d['first_name']} ${d['last_name'] ?? ''}'.trim()
                          : 'Anonymous';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.payments, color: categoryColor),
                          ),
                          title: Text(
                            memberName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${d['category_name'] ?? 'Uncategorized'} - ${d['payment_method'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          trailing: Text(
                            _formatAmount(d['amount']),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
