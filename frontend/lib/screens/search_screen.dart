import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/member.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Member> _memberResults = [];
  List<ChurchEvent> _eventResults = [];
  List<ChurchEvent> _allEvents = [];
  bool _loading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _preloadEvents();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _preloadEvents() async {
    try {
      final res = await ApiService.get('/events', queryParameters: {'limit': 100});
      final List<dynamic> data = res['data'] ?? res;
      _allEvents = data.map((e) => ChurchEvent.fromJson(e)).toList();
    } catch (e) {
      // ignore, search will just show no event results
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _memberResults = [];
        _eventResults = [];
        _hasSearched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(query.trim()));
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      final res = await ApiService.get('/members', queryParameters: {'search': query, 'limit': 10});
      final List<dynamic> data = res['data'] ?? res;
      final members = data.map((m) => Member.fromJson(m)).toList();

      final lowerQuery = query.toLowerCase();
      final events = _allEvents
          .where((e) =>
              e.title.toLowerCase().contains(lowerQuery) ||
              e.location.toLowerCase().contains(lowerQuery))
          .toList();

      setState(() {
        _memberResults = members;
        _eventResults = events;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onQueryChanged,
          decoration: const InputDecoration(
            hintText: 'Search members, events...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: !_hasSearched
          ? const Center(
              child: Text('Start typing to search', style: TextStyle(color: Colors.grey)),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : (_memberResults.isEmpty && _eventResults.isEmpty)
                  ? const Center(child: Text('No results found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_memberResults.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Members',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          ..._memberResults.map((m) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFDBEAFE),
                                    child: Text(m.initials,
                                        style: const TextStyle(color: Color(0xFF1E40AF))),
                                  ),
                                  title: Text(m.fullName),
                                  subtitle: Text(m.email ?? m.phone ?? ''),
                                  onTap: () => context.push('/members/${m.id}'),
                                ),
                              )),
                          const SizedBox(height: 16),
                        ],
                        if (_eventResults.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Events',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          ..._eventResults.map((e) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.event, color: Color(0xFFEA580C)),
                                  title: Text(e.title),
                                  subtitle: Text('${e.shortDate} - ${e.location}'),
                                  onTap: () => context.push('/events'),
                                ),
                              )),
                        ],
                      ],
                    ),
    );
  }
}
