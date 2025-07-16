import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMemberScreen extends StatelessWidget {
  const AddMemberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final addressCtl = TextEditingController();
    final dateCtl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: addressCtl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: dateCtl,
              decoration: const InputDecoration(labelText: 'Joined Date (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtl.text.trim();
                final phone = phoneCtl.text.trim();
                final address = addressCtl.text.trim();
                final dateText = dateCtl.text.trim();

                // Basic validation
                if (name.isEmpty || phone.isEmpty || address.isEmpty || dateText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All fields are required.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Date parsing
                DateTime? parsedDate;
                try {
                  parsedDate = DateTime.parse(dateText);
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid date format. Use YYYY-MM-DD'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('members').add({
                    'name': name,
                    'phone': phone,
                    'address': address,
                    'joinedDate': Timestamp.fromDate(parsedDate),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Member added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add member: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ]),
        ),
      ),
    );
  }
}
