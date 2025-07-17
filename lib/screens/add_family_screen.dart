import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddFamilyMemberScreen extends StatelessWidget {
  final String familyId;
  const AddFamilyMemberScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final addressCtl = TextEditingController();
    final dateCtl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Family Member", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneCtl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: addressCtl, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: dateCtl, decoration: const InputDecoration(labelText: 'Joined Date (YYYY-MM-DD)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtl.text.trim();
                final phone = phoneCtl.text.trim();
                final address = addressCtl.text.trim();
                final dateText = dateCtl.text.trim();

                if (name.isEmpty || phone.isEmpty || address.isEmpty || dateText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                  return;
                }

                DateTime? parsedDate;
                try {
                  parsedDate = DateTime.parse(dateText);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid date format")));
                  return;
                }

                final data = {
                  'name': name,
                  'phone': phone,
                  'address': address,
                  'joinedDate': Timestamp.fromDate(parsedDate),
                  'familyId': familyId,
                  'isFamily': true,
                };

                await FirebaseFirestore.instance.collection('members').add(data);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Family member added')),
                );
              },
              child: const Text("Save"),
            ),
          ]),
        ),
      ),
    );
  }
}
