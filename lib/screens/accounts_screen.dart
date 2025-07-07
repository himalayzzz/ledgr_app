import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ledgr/screens/event_detail_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Events',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 🔥 List Events from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text('No events yet.');
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data()! as Map<String, dynamic>;

                      final eventTitle = data['title'] ?? '';
                      final eventDate = (data['date'] as Timestamp).toDate();

                      return _EventTile(
                        eventId: doc.id,
                        title: eventTitle,
                        date: eventDate,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                      labelText: 'Date (e.g., 2025-06-30)')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final dateStr = dateController.text.trim();

                if (title.isEmpty || dateStr.isEmpty) return;

                final date = DateTime.tryParse(dateStr);
                if (date == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid date format')),
                  );
                  return;
                }

                final newEvent = await FirebaseFirestore.instance
                    .collection('events')
                    .add({
                  'title': title,
                  'date': Timestamp.fromDate(date),
                });

                Navigator.pop(context);

                // Navigate to Event Detail
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailScreen(
                      eventId: newEvent.id,
                      eventTitle: title,
                      eventDate:
                          '${date.year}-${date.month}-${date.day}', // or use intl
                    ),
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final String eventId;
  final String title;
  final DateTime date;

  const _EventTile({
    required this.eventId,
    required this.title,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text('${date.year}-${date.month}-${date.day}'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              eventId: eventId,
              eventTitle: title,
              eventDate: '${date.year}-${date.month}-${date.day}',
            ),
          ),
        );
      },
    );
  }
}
