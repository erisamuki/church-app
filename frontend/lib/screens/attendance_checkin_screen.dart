import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

/// Step 1: pick which event to check members into
class EventPickerScreen extends StatefulWidget {
  const EventPickerScreen({super.key});

  @override
  State<EventPickerScreen> createState() => _EventPickerScreenState();
}

class _EventPickerScreenState extends State<EventPickerScreen> {
  List<ChurchEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final res = await ApiService.get('/events', queryParameters: {'limit': 50});
      final json = res;
      final List<dynamic> data = json['data'] ?? json;
      setState(() {
        _events = data.map((e) => ChurchEvent.fromJson(e)).toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate));
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Record Attendance',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('No events found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final e = _events[index];
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
                            color: const Color(0xFFFFF1E6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${e.startDate.day}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ),
                        ),
                        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${e.shortDate} - ${e.location}'),
                        trailing: const Icon(Icons.qr_code_scanner),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QrCheckinScannerScreen(event: e),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

/// Step 2: scan member QR codes and check them in to the selected event
class QrCheckinScannerScreen extends StatefulWidget {
  final ChurchEvent event;
  const QrCheckinScannerScreen({super.key, required this.event});

  @override
  State<QrCheckinScannerScreen> createState() => _QrCheckinScannerScreenState();
}

class _QrCheckinScannerScreenState extends State<QrCheckinScannerScreen> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  String? _lastMessage;
  bool _lastSuccess = false;
  int _checkedInCount = 0;
  final Set<String> _recentlyScanned = {};

  String? _cameraError;
  bool _cameraStarting = true;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(autoStart: false);
    _startCamera();
  }

  Future<void> _startCamera() async {
    setState(() {
      _cameraStarting = true;
      _cameraError = null;
    });
    try {
      await _controller.start();
      if (mounted) {
        setState(() {
          _cameraStarting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraStarting = false;
          _cameraError = 'Could not start camera: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    final memberId = barcode?.rawValue;
    if (memberId == null || memberId.isEmpty) return;

    if (_recentlyScanned.contains(memberId)) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final res = await ApiService.post(
        '/events/${widget.event.id}/checkin',
        {'member_id': memberId},
      );

      final success = res['success'] == true;
      setState(() {
        _lastSuccess = success;
        _lastMessage = success ? 'Checked in successfully' : (res['message'] ?? 'Check-in failed');
        if (success) _checkedInCount++;
      });

      _recentlyScanned.add(memberId);
      Future.delayed(const Duration(seconds: 5), () {
        _recentlyScanned.remove(memberId);
      });
    } catch (e) {
      setState(() {
        _lastSuccess = false;
        _lastMessage = 'Network error during check-in';
      });
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '$_checkedInCount checked in',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _cameraError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_off, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _cameraError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _startCamera,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _onDetect,
                      ),
                      if (_cameraStarting)
                        const Center(child: CircularProgressIndicator(color: Colors.white)),
                      if (!_cameraStarting)
                        Center(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      if (_isProcessing)
                        const Positioned(
                          top: 20,
                          left: 0,
                          right: 0,
                          child: Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                    ],
                  ),
          ),
          if (_lastMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _lastSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _lastSuccess ? Icons.check_circle : Icons.error,
                    color: _lastSuccess ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _lastMessage!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _lastSuccess ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
