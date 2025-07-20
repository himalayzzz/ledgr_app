import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddMemberScreen extends StatelessWidget {
  final String? memberId; // null means new member
  final Map<String, dynamic>? existingData;

  const AddMemberScreen({super.key, this.memberId, this.existingData});

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
          isEditing ? 'Edit Member' : 'Add Member',
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
  'isFamily': false,
  'familyId': isEditing
      ? (existingData?['familyId'] ?? '')
      : const Uuid().v4(),
};



                  if (isEditing) {
                    await FirebaseFirestore.instance.collection('members').doc(memberId).update(data);
                  } else {
                    await FirebaseFirestore.instance.collection('members').add(data);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEditing ? '✅ Member updated' : '✅ Member added')),
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
