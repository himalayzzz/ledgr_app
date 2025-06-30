import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledgr - Dashboard',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // ✅ Wrap without Expanded
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
                children: const [
                  _MemberRowHeader(),
                  Divider(height: 0),
                  _MemberRow(
                    name: 'John Abraham',
                    date: 'May 20, 2025',
                    phone: '9876543210',
                    address: '123 Main St, City, Country',

                  ),
                  _MemberRow(
                    name: 'Priya Daniel',
                    date: 'May 25, 2025',
                    phone: '9876543211',
                    address: '456 Elm St, City, Country',
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
class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;

  const _SummaryCard({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(amount, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _ActionButton({required this.label, required this.icon, required this.route});

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
class _MemberRowHeader extends StatelessWidget {
  const _MemberRowHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text('Joined Date', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(width: 50), // For action button
      ],
    );
  }
}
class _MemberRow extends StatelessWidget {
  final String name;
  final String date;
  final String phone;
  final String address;
  //final VoidCallback action;

  const _MemberRow({required this.name, required this.date, required this.phone, required this.address,
  });

  

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(name)),
        Expanded(child: Text(date)),
        Expanded(child: Text(phone)),
        Expanded(child: Text(address)),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: (){
            showEditMemberDialog(context,
              name: name,
              phone: phone,
              date: date,
              address: address,
              onSave: () {
          }
            );}
        ),
      ],
    );
  }
}
void showEditMemberDialog(BuildContext context, {
  required String name,
  required String phone,
  required String date,
  required String address,
  required VoidCallback onSave,
}) {
  final nameController = TextEditingController(text: name);
  final phoneController = TextEditingController(text: phone);
  final dateController = TextEditingController(text: date);
  final addressController = TextEditingController(text: address);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Joined Date'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Save updated values to Firestore or local state
            onSave(); // callback
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Member details updated.')),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
