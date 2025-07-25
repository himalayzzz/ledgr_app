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

  String formatDateToDDMMYYYY(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  DateTime? parseDDMMYYYY(String input) {
    try {
      final parts = input.split('-');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameCtl = TextEditingController(text: existingData?['name'] ?? '');
    final phoneCtl = TextEditingController(text: existingData?['phone'] ?? '');
    final addressCtl = TextEditingController(text: existingData?['address'] ?? '');

    final joinedDate = existingData?['joinedDate'] as Timestamp?;
    final dateCtl = TextEditingController(
      text: joinedDate != null ? formatDateToDDMMYYYY(joinedDate.toDate()) : '',
    );

    final isEditing = memberId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'JSOC- Edit Family Member' : 'JSOC- Add Family Member',
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
              TextField(
                controller: dateCtl,
                decoration: const InputDecoration(labelText: 'Joined Date (DD-MM-YYYY)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtl.text.trim();
                  final phone = phoneCtl.text.trim();
                  final address = addressCtl.text.trim();
                  final dateStr = dateCtl.text.trim();

                  if (name.isEmpty || phone.isEmpty || address.isEmpty || dateStr.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All fields are required')),
                    );
                    return;
                  }

                  final parsedDate = parseDDMMYYYY(dateStr);
                  if (parsedDate == null) {
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
