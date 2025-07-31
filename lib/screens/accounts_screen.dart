import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ledgr/screens/event_detail_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final Map<String, bool> _expandedMainEvents = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('St. Joseph JSOC- Accounts',
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('type', isEqualTo: 'main')
                    .snapshots(), // Removed orderBy to avoid index requirement
                builder: (context, snapshot) {
                  // Add better error handling
                  if (snapshot.hasError) {
                    print('Error: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error loading events: ${snapshot.error}'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Trigger rebuild
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text('No data available'));
                  }

                  final mainEvents = snapshot.data!.docs;

                  if (mainEvents.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No events yet.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to create your first event',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort events by date in memory instead of in query
                  mainEvents.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aDate = (aData['date'] as Timestamp).toDate();
                    final bDate = (bData['date'] as Timestamp).toDate();
                    return bDate.compareTo(aDate); // Descending order
                  });

                  return ListView.builder(
                    itemCount: mainEvents.length,
                    itemBuilder: (context, index) {
                      final mainEvent = mainEvents[index];
                      final mainEventData = mainEvent.data()! as Map<String, dynamic>;
                      final mainEventTitle = mainEventData['title'] ?? '';
                      final mainEventDate = (mainEventData['date'] as Timestamp).toDate();
                      final mainEventId = mainEvent.id;

                      final isExpanded = _expandedMainEvents[mainEventId] ?? false;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            // Main Event
                            ListTile(
                              leading: Icon(
                                isExpanded ? Icons.folder_open : Icons.folder,
                                color: Colors.blue,
                                size: 28,
                              ),
                              title: Text(
                                mainEventTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                DateFormat('dd-MM-yyyy').format(mainEventDate),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Sub events count
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('events')
                                        .where('mainEventId', isEqualTo: mainEventId)
                                        .where('type', isEqualTo: 'sub')
                                        .snapshots(),
                                    builder: (context, subSnapshot) {
                                      if (subSnapshot.hasError) {
                                        return const SizedBox();
                                      }
                                      
                                      final subCount = subSnapshot.hasData 
                                          ? subSnapshot.data!.docs.length 
                                          : 0;
                                      
                                      return subCount > 0
                                          ? Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '$subCount',
                                                style: const TextStyle(
                                                    color: Colors.white, fontSize: 12),
                                              ),
                                            )
                                          : const SizedBox();
                                    },
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditEventDialog(context, mainEventId,
                                            mainEventTitle, mainEventDate);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(context, mainEventId);
                                      } else if (value == 'addSub') {
                                        _showAddSubEventDialog(context, mainEventId, mainEventTitle);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit Main Event'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'addSub',
                                        child: Text('Add Sub Event'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete Main Event'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Toggle expand/collapse
                                setState(() {
                                  _expandedMainEvents[mainEventId] = !isExpanded;
                                });
                              },
                              onLongPress: () {
                                // Long press to open main event directly
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailScreen(
                                      eventId: mainEventId,
                                      eventTitle: mainEventTitle,
                                      eventDate: DateFormat('dd-MM-yyyy')
                                          .format(mainEventDate),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            // Sub Events (collapsible)
                            if (isExpanded)
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('events')
                                    .where('mainEventId', isEqualTo: mainEventId)
                                    .where('type', isEqualTo: 'sub')
                                    .snapshots(), // Removed orderBy here too
                                builder: (context, subSnapshot) {
                                  if (subSnapshot.hasError) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 32),
                                          Icon(Icons.error, color: Colors.red, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Error loading sub events',
                                            style: TextStyle(color: Colors.red, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (!subSnapshot.hasData) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final subEvents = subSnapshot.data!.docs;

                                  if (subEvents.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 32),
                                          Icon(Icons.info_outline, 
                                              color: Colors.grey[600], size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'No sub events yet',
                                            style: TextStyle(
                                                color: Colors.grey[600], fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  // Sort sub events by date in memory
                                  subEvents.sort((a, b) {
                                    final aData = a.data() as Map<String, dynamic>;
                                    final bData = b.data() as Map<String, dynamic>;
                                    final aDate = (aData['date'] as Timestamp).toDate();
                                    final bDate = (bData['date'] as Timestamp).toDate();
                                    return bDate.compareTo(aDate); // Descending order
                                  });

                                  return Column(
                                    children: subEvents.map((subEvent) {
                                      final subEventData =
                                          subEvent.data()! as Map<String, dynamic>;
                                      final subEventTitle = subEventData['title'] ?? '';
                                      final subEventDate =
                                          (subEventData['date'] as Timestamp).toDate();

                                      return Container(
                                        margin: const EdgeInsets.only(left: 32, right: 8, bottom: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange[200]!),
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          leading: Icon(
                                            Icons.description,
                                            color: Colors.orange[700],
                                            size: 20,
                                          ),
                                          title: Text(
                                            subEventTitle,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          subtitle: Text(
                                            DateFormat('dd-MM-yyyy').format(subEventDate),
                                            style: TextStyle(
                                                color: Colors.grey[600], fontSize: 12),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 4, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('SUB',
                                                    style: TextStyle(
                                                        color: Colors.white, fontSize: 8)),
                                              ),
                                              PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _showEditSubEventDialog(context,
                                                        subEvent.id, subEventTitle, subEventDate);
                                                  } else if (value == 'delete') {
                                                    _showDeleteSubConfirmation(
                                                        context, subEvent.id);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Text('Edit Sub Event'),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text('Delete Sub Event'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EventDetailScreen(
                                                  eventId: subEvent.id,
                                                  eventTitle: subEventTitle,
                                                  eventDate: DateFormat('dd-MM-yyyy')
                                                      .format(subEventDate),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                          ],
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
        onPressed: () => _showAddEventDialog(context),
        tooltip: 'Add Main Event',
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
          title: const Text('Add Main Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Event Name')),
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

                  final currentUser = FirebaseAuth.instance.currentUser;
                  final userEmail = currentUser?.email ?? 'unknown@example.com';

                  await FirebaseFirestore.instance.collection('events').add({
                    'title': title,
                    'date': Timestamp.fromDate(date),
                    'type': 'main',
                    'createdBy': userEmail,
                    'createdAt': Timestamp.now(),
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Main event created successfully')),
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

  void _showAddSubEventDialog(BuildContext context, String mainEventId, String mainEventTitle) {
    final titleController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Sub Event to "$mainEventTitle"'),
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

                  final currentUser = FirebaseAuth.instance.currentUser;
                  final userEmail = currentUser?.email ?? 'unknown@example.com';

                  await FirebaseFirestore.instance.collection('events').add({
                    'title': title,
                    'date': Timestamp.fromDate(date),
                    'type': 'sub',
                    'mainEventId': mainEventId,
                    'mainEventTitle': mainEventTitle,
                    'createdBy': userEmail,
                    'createdAt': Timestamp.now(),
                  });

                  Navigator.pop(context);

                  // Ensure the main event is expanded to show the new sub event
                  setState(() {
                    _expandedMainEvents[mainEventId] = true;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sub event created successfully')),
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

  void _showEditEventDialog(BuildContext context, String eventId,
      String currentTitle, DateTime currentDate) {
    final titleController = TextEditingController(text: currentTitle);
    final dateController =
        TextEditingController(text: DateFormat('dd-MM-yyyy').format(currentDate));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Main Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Event Name')),
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

                  final currentUser = FirebaseAuth.instance.currentUser;
                  final userEmail = currentUser?.email ?? 'unknown@example.com';

                  await FirebaseFirestore.instance
                      .collection('events')
                      .doc(eventId)
                      .update({
                    'title': title,
                    'date': Timestamp.fromDate(date),
                    'lastModifiedBy': userEmail,
                    'lastModifiedAt': Timestamp.now(),
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

                  final currentUser = FirebaseAuth.instance.currentUser;
                  final userEmail = currentUser?.email ?? 'unknown@example.com';

                  await FirebaseFirestore.instance
                      .collection('events')
                      .doc(eventId)
                      .update({
                    'title': title,
                    'date': Timestamp.fromDate(date),
                    'lastModifiedBy': userEmail,
                    'lastModifiedAt': Timestamp.now(),
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
        content: const Text('Do you want to delete this main event and all its sub events?'),
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
                  content: const Text('This action cannot be undone. All sub events will also be deleted.'),
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
                // Delete all sub events first
                final subEvents = await FirebaseFirestore.instance
                    .collection('events')
                    .where('mainEventId', isEqualTo: eventId)
                    .get();
                
                for (var subEvent in subEvents.docs) {
                  await subEvent.reference.delete();
                }

                // Then delete the main event
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

  void _showDeleteSubConfirmation(BuildContext context, String eventId) {
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