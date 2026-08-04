import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/communications_provider.dart';

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunicationsProvider>().fetchCommunications();
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return Icons.email_outlined;
      case 'sms':
        return Icons.sms_outlined;
      case 'announcement':
      default:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunicationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communications', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement compose message modal or screen
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Compose', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBody(CommunicationsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchCommunications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.messages.isEmpty) {
      return const Center(child: Text('No messages found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        final isSent = message.status.toLowerCase() == 'sent';

        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                child: Icon(
                  _getIconForType(message.type),
                  color: Colors.black87,
                ),
              ),
              title: Text(
                message.subject,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    message.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSent ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          message.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSent ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, yyyy h:mm a').format(message.sentAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                // TODO: View full communication detail
              },
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}
