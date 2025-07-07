import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final membersCol = FirebaseFirestore.instance.collection('members');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ledgr - Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: const [
                _ActionButton(label: 'Add Member', icon: Icons.person_add, route: '/add-member'),
                _ActionButton(label: 'Accounts', icon: Icons.account_balance_wallet, route: '/accounts'),
                _ActionButton(label: 'View Records', icon: Icons.filter_alt, route: '/view-records'),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Members',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const _MemberRowHeader(),
                  const Divider(height: 0),
                  StreamBuilder<QuerySnapshot>(
                    stream: membersCol.orderBy('joinedDate').snapshots(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snap.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              '❌ Error loading members.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text('No members found.'),
                          ),
                        );
                      }

                      final docs = snap.data!.docs;

                      return Column(
                        children: docs.map((doc) {
                          final raw = doc.data();
                          if (raw == null || raw is! Map<String, dynamic>) return const SizedBox();

                          final name = raw['name'] ?? '';
                          final phone = raw['phone'] ?? '';
                          final address = raw['address'] ?? '';
                          final joinedTimestamp = raw['joinedDate'] as Timestamp?;
                          final date = joinedTimestamp != null
                              ? joinedTimestamp.toDate().toIso8601String().split('T').first
                              : '';

                          return _MemberRow(
                            name: name,
                            phone: phone,
                            address: address,
                            date: date,
                            onEdit: () => showEditMemberDialog(context, doc),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Reusable Action Button
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 50),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}

// 🔹 Table Header
class _MemberRowHeader extends StatelessWidget {
  const _MemberRowHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text('Joined Date', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(width: 50), // Edit button space
      ],
    );
  }
}

// 🔹 Table Row with Edit
class _MemberRow extends StatelessWidget {
  final String name;
  final String phone;
  final String date;
  final String address;
  final VoidCallback onEdit;

  const _MemberRow({
    required this.name,
    required this.date,
    required this.phone,
    required this.address,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(name)),
        Expanded(child: Text(date)),
        Expanded(child: Text(phone)),
        Expanded(child: Text(address)),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
      ],
    );
  }
}

// 🔹 Edit Member Dialog (Firestore Update)
void showEditMemberDialog(BuildContext context, QueryDocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final nameCtl = TextEditingController(text: data['name'] ?? '');
  final phoneCtl = TextEditingController(text: data['phone'] ?? '');
  final addressCtl = TextEditingController(text: data['address'] ?? '');
  final dateCtl = TextEditingController(
    text: (data['joinedDate'] as Timestamp?)
            ?.toDate()
            .toIso8601String()
            .split('T')
            .first ??
        '',
  );

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: dateCtl, decoration: const InputDecoration(labelText: 'Joined Date (YYYY-MM-DD)')),
            TextField(controller: addressCtl, decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            try {
              final parsedDate = DateTime.tryParse(dateCtl.text);
              if (parsedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid date format')),
                );
                return;
              }

              await doc.reference.update({
                'name': nameCtl.text,
                'phone': phoneCtl.text,
                'address': addressCtl.text,
                'joinedDate': Timestamp.fromDate(parsedDate),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member details updated.')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Update failed: $e')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
