import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import 'assign_volunteer_screen.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  List<ChurchEvent> _events = [];
  ChurchEvent? _selectedEvent;
  List<Map<String, dynamic>> _assignments = [];
  bool _loadingEvents = true;
  bool _loadingAssignments = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final res = await ApiService.get('/events', queryParameters: {'limit': 50});
      final List<dynamic> data = res['data'] ?? res;
      final events = data.map((e) => ChurchEvent.fromJson(e)).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      setState(() {
        _events = events;
        _loadingEvents = false;
        if (events.isNotEmpty) {
          _selectedEvent = events.first;
          _loadAssignments(events.first.id);
        }
      });
    } catch (e) {
      setState(() => _loadingEvents = false);
    }
  }

  Future<void> _loadAssignments(String eventId) async {
    setState(() => _loadingAssignments = true);
    try {
      final res = await ApiService.get('/volunteers/assignments/$eventId');
      final List<dynamic> data = res['data'] ?? res;
      setState(() {
        _assignments = data.cast<Map<String, dynamic>>();
        _loadingAssignments = false;
      });
    } catch (e) {
      setState(() {
        _assignments = [];
        _loadingAssignments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Volunteers',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_alt),
          onPressed: _selectedEvent == null
              ? null
              : () async {
                  final assigned = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignVolunteerScreen(event: _selectedEvent!),
                    ),
                  );
                  if (assigned == true) {
                    _loadAssignments(_selectedEvent!.id);
                  }
                },
        ),
      ],
      body: _loadingEvents
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('No events found'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<ChurchEvent>(
                        initialValue: _selectedEvent,
                        decoration: const InputDecoration(
                          labelText: 'Select Event',
                          border: OutlineInputBorder(),
                        ),
                        items: _events
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('${e.title} - ${e.shortDate}'),
                                ))
                            .toList(),
                        onChanged: (e) {
                          if (e != null) {
                            setState(() => _selectedEvent = e);
                            _loadAssignments(e.id);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: _loadingAssignments
                          ? const Center(child: CircularProgressIndicator())
                          : _assignments.isEmpty
                              ? const Center(child: Text('No volunteers assigned yet'))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _assignments.length,
                                  itemBuilder: (context, index) {
                                    final a = _assignments[index];
                                    final roleColor = a['color'] != null
                                        ? Color(int.parse(
                                            (a['color'] as String).replaceFirst('#', '0xFF')))
                                        : const Color(0xFF64748B);
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: roleColor.withValues(alpha: 0.15),
                                          child: Icon(Icons.volunteer_activism,
                                              color: roleColor, size: 20),
                                        ),
                                        title: Text(
                                          '${a['first_name']} ${a['last_name']}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        subtitle:
                                            Text('${a['role_name']} - ${a['department'] ?? ''}'),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            a['status'] ?? 'confirmed',
                                            style: const TextStyle(
                                                fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
    );
  }
}
