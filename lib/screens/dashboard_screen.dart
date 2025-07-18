import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgr/screens/add_family_screen.dart';
import 'package:ledgr/screens/add_member_screen.dart';
import 'package:ledgr/screens/accounts_screen.dart';
import 'package:ledgr/screens/view_records_screen.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final membersCol = FirebaseFirestore.instance.collection('members');
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F9),
      appBar: AppBar(
        title: const Text('Ledgr Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // ================= Quick Actions Section =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 158, 234, 236),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final newFamilyId = const Uuid().v4();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMemberScreen(familyId: newFamilyId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountsScreen()),
                      );
                    },
                    icon: const Icon(Icons.attach_money),
                    label: const Text('Accounts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ViewRecordsScreen()),
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('View Records'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ========== Search Bar ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search members by name...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              ),
            ),

            const SizedBox(height: 8),

            // ========== Members List ==========
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: membersCol.orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  final heads = <Map<String, dynamic>>[];
                  final families = <String, List<Map<String, dynamic>>>{};

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    if (searchQuery.isNotEmpty && !name.contains(searchQuery)) continue;

                    final isFamily = data['isFamily'] ?? false;
                    final familyId = data['familyId'] ?? '';
                    data['id'] = id;

                    if (isFamily && familyId.isNotEmpty) {
                      families.putIfAbsent(familyId, () => []).add(data);
                    } else {
                      heads.add(data);
                    }
                  }

                  if (heads.isEmpty) {
                    return const Center(child: Text('No members yet.'));
                  }

                  return ListView.builder(
                    itemCount: heads.length,
                    itemBuilder: (context, index) {
                      final head = heads[index];
                      final familyId = head['familyId'] ?? '';
                      final headName = head['name'] ?? '';
                      final phone = head['phone'] ?? '';
                      final joinedDate = (head['joinedDate'] as Timestamp?)?.toDate();
                      final address = head['address'] ?? '';
                      final docId = head['id'];
                      final children = families[familyId] ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: ExpansionTile(
                          title: Text(headName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Phone: $phone\nAddress: $address'),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit Member',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddMemberScreen(
                                          familyId: familyId,
                                          memberId: docId,
                                          existingData: head,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.group_add),
                                  tooltip: 'Add Family Member',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddFamilyMemberScreen(
                                          familyId: familyId,
                   
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                              ],
                            ),
                            if (children.isNotEmpty) ...[
                              const Divider(),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Family Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              ...children.map((member) {
                                final memberName = member['name'] ?? '';
                                final memberPhone = member['phone'] ?? '';
                                final memberAddress = member['address'] ?? '';
                                final joined = (member['joinedDate'] as Timestamp?)?.toDate();

                                return ListTile(
                                  title: Text(memberName),
                                  subtitle: Text('Phone: $memberPhone\nAddress: $memberAddress'),
                                  trailing: Text(joined != null
                                      ? '${joined.year}-${joined.month.toString().padLeft(2, '0')}-${joined.day.toString().padLeft(2, '0')}'
                                      : 'N/A'),
                                );
                              }).toList(),
                            ]
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
