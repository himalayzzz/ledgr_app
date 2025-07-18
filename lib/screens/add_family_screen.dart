import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddFamilyMemberScreen extends StatelessWidget {
  final String familyId;
  final String? memberId; // If not null, we're editing
  final Map<String, dynamic>? existingData;

  const AddFamilyMemberScreen({
    super.key,
    required this.familyId,
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

    final isEditing = memberId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Family Member' : 'Add Family Member',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: addressCtl, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: dateCtl, decoration: const InputDecoration(labelText: 'Joined Date (YYYY-MM-DD)')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtl.text.trim();
                  final phone = phoneCtl.text.trim();
                  final address = addressCtl.text.trim();
                  final date = dateCtl.text.trim();

                  if (name.isEmpty || phone.isEmpty || address.isEmpty || date.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All fields are required')),
                    );
                    return;
                  }

                  DateTime? parsedDate;
                  try {
                    parsedDate = DateTime.parse(date);
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid date format')),
                    );
                    return;
                  }

                  final data = {
                    'name': name,
                    'phone': phone,
                    'address': address,
                    'joinedDate': Timestamp.fromDate(parsedDate),
                    'isFamily': true,
                    'familyId': familyId,
                  };

                  if (isEditing) {
                    await FirebaseFirestore.instance.collection('members').doc(memberId).update(data);
                  } else {
                    await FirebaseFirestore.instance.collection('members').add(data);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEditing ? '✅ Family Member updated' : '✅ Family Member added')),
                  );
                },
                child: Text(isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
