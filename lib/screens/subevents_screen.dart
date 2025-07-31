import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgr/screens/event_detail_screen.dart';

class SubEventsScreen extends StatelessWidget {
  final String mainEventId;
  final String mainEventTitle;

  const SubEventsScreen({
    super.key,
    required this.mainEventId,
    required this.mainEventTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sub Events - $mainEventTitle',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sub Events',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('mainEventId', isEqualTo: mainEventId)
                    .where('type', isEqualTo: 'sub')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text('No sub events yet.');
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data()! as Map<String, dynamic>;

                      final eventTitle = data['title'] ?? '';
                      final eventDate = (data['date'] as Timestamp).toDate();

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(eventTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('SUB',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10)),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            DateFormat('dd-MM-yyyy').format(eventDate),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditSubEventDialog(
                                    context, doc.id, eventTitle, eventDate);
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(context, doc.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(
                                  eventId: doc.id,
                                  eventTitle: eventTitle,
                                  eventDate: DateFormat('dd-MM-yyyy')
                                      .format(eventDate),
                                ),
                              ),
                            );
                          },
                        ),
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
        onPressed: () => _showAddSubEventDialog(context),
        tooltip: 'Add Sub Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSubEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Sub Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Sub Event Name')),
              TextField(
                  controller: dateController,
                  decoration:
                      const InputDecoration(labelText: 'Date (dd-MM-yyyy)')),
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

                try {
                  final date = DateFormat('dd-MM-yyyy').parseStrict(dateStr);
                  if (title.isEmpty) throw Exception();

                  final newSubEvent = await FirebaseFirestore.instance
                      .collection('events')
                      .add({
                    'title': title,
                    'date': Timestamp.fromDate(date),
                    'type': 'sub',
                    'mainEventId': mainEventId,
                    'mainEventTitle': mainEventTitle,
                  });

                  Navigator.pop(context);

                  // Navigate to event detail screen for the new sub event
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailScreen(
                        eventId: newSubEvent.id,
                        eventTitle: title,
                        eventDate: DateFormat('dd-MM-yyyy').format(date),
                      ),
                    ),
                  );
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid input. Use dd-MM-yyyy format')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSubEventDialog(BuildContext context, String eventId,
      String currentTitle, DateTime currentDate) {
    final titleController = TextEditingController(text: currentTitle);
    final dateController =
        TextEditingController(text: DateFormat('dd-MM-yyyy').format(currentDate));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Sub Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Sub Event Name')),
              TextField(
                  controller: dateController,
                  decoration:
                      const InputDecoration(labelText: 'Date (dd-MM-yyyy)')),
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

                try {
                  final date = DateFormat('dd-MM-yyyy').parseStrict(dateStr);
                  if (title.isEmpty) throw Exception();

                  await FirebaseFirestore.instance
                      .collection('events')
                      .doc(eventId)
                      .update({
                    'title': title,
                    'date': Timestamp.fromDate(date),
                  });

                  Navigator.pop(context);
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid input. Use dd-MM-yyyy format')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Do you want to delete this sub event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final sure = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Are you sure?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Yes')),
                  ],
                ),
              );

              if (sure == true) {
                await FirebaseFirestore.instance
                    .collection('events')
                    .doc(eventId)
                    .delete();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}