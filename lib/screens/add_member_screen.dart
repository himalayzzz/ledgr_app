import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  Future<void> _addMember() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('members').add({
      'name': name,
      'phone': phone,
      'address': address,
      'joinedDate': Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member',style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _addressController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addMember,
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }
}
