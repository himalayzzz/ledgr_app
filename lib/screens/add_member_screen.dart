import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class AddMemberScreen extends StatelessWidget {
  final String familyId; // ✅ Now this must be passed from outside
  final String? memberId;
  final Map<String, dynamic>? existingData;

  const AddMemberScreen({
    super.key,
    required this.familyId, // ✅ REQUIRED — must be passed
    this.memberId,
    this.existingData,
  });

  @override
  Widget build(BuildContext context) {
    final nameCtl = TextEditingController(text: existingData?['name'] ?? '');
    final phoneCtl = TextEditingController(text: existingData?['phone'] ?? '');
    final addressCtl = TextEditingController(text: existingData?['address'] ?? '');
    final dateCtl = TextEditingController(
      text: existingData?['joinedDate'] != null
          ? (existingData!['joinedDate'] as Timestamp).toDate().toString().split(' ')[0]
          : '',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          memberId != null ? 'Edit Member' : 'Add Member',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
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

                if (name.isEmpty || phone.isEmpty || address.isEmpty || dateText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required'), backgroundColor: Colors.red),
                  );
                  return;
                }

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

                final data = {
                  'name': name,
                  'phone': phone,
                  'address': address,
                  'joinedDate': Timestamp.fromDate(parsedDate),
                  'familyId': familyId, // ✅ Always set this
                };

                if (memberId != null) {
                  await FirebaseFirestore.instance.collection('members').doc(memberId).update(data);
                } else {
                  await FirebaseFirestore.instance.collection('members').add(data);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Member saved successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ]),
        ),
      ),
    );
  }
}
