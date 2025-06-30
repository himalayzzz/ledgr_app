import 'package:flutter/material.dart';
import 'package:ledgr/screens/event_detail_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts',style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.blue,),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Example Event (Replace with Firestore data)
          _EventTile(title: 'Sunday Offering', date: 'June 23, 2025'),
          _EventTile(title: 'Special Fundraiser', date: 'June 10, 2025'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEventDialog(context);
        },
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
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (e.g., June 30, 2025)')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(
                    eventId: 'abc123', // Firebase doc ID
                    eventTitle: 'Sunday Offering',
                    eventDate: 'June 30, 2025',
                  ),
                ),
              );

                // Save to Firestore here
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
  final String title;
  final String date;

  const _EventTile({required this.title, required this.date});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(date),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.pushNamed(context, '/event-detail'); // Route to be created
      },
    );
  }
}
