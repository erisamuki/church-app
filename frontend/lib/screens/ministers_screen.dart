import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import 'add_minister_screen.dart';

class MinistersScreen extends StatefulWidget {
  const MinistersScreen({super.key});

  @override
  State<MinistersScreen> createState() => _MinistersScreenState();
}

class _MinistersScreenState extends State<MinistersScreen> {
  List<Map<String, dynamic>> _ministers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMinisters();
  }

  Future<void> _loadMinisters() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/ministers');
      final List<dynamic> data = res['data'] ?? res;
      setState(() {
        _ministers = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Leadership',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMinisterScreen()),
            );
            if (added == true) _loadMinisters();
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadMinisters,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _ministers.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No leaders added yet')),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      childAspectRatio: 2.6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _ministers.length,
                    itemBuilder: (context, index) {
                      final m = _ministers[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFFFFF1E6),
                                backgroundImage:
                                    m['photo_url'] != null ? NetworkImage(m['photo_url']) : null,
                                child: m['photo_url'] == null
                                    ? Text(
                                        (m['full_name'] ?? '?').toString().substring(0, 1),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Color(0xFFEA580C),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      m['full_name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      m['title'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFEA580C),
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (m['department'] != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        m['department'],
                                        style:
                                            const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
