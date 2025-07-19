import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgr/screens/add_family_screen.dart';
import 'package:ledgr/screens/add_member_screen.dart';
import 'package:ledgr/screens/accounts_screen.dart';
import 'package:ledgr/screens/view_records_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final membersCol = FirebaseFirestore.instance.collection('members');
  String searchQuery = '';
  bool showHidden = false;

  Future<void> _deleteMember(String docId) async {
    await membersCol.doc(docId).delete();
  }

  Future<void> _toggleHideMember(String docId, bool currentHidden) async {
    await membersCol.doc(docId).update({'isHidden': !currentHidden});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F9),
      appBar: AppBar(
        title: const Text('Ledgr Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(showHidden ? Icons.visibility_off : Icons.visibility),
            tooltip: showHidden ? 'Hide Hidden Members' : 'Show Hidden Members',
            onPressed: () => setState(() => showHidden = !showHidden),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMemberScreen(existingData: null, memberId: null),
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: membersCol.orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  final heads = <Map<String, dynamic>>[];
                  final families = <String, List<Map<String, dynamic>>>{};

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final isHidden = data['isHidden'] ?? false;

                    if (!showHidden && isHidden) continue;

                    final isFamily = data['isFamily'] ?? false;
                    final familyId = data['familyId'] ?? '';
                    data['id'] = id;

                    if (isFamily && familyId.isNotEmpty) {
                      families.putIfAbsent(familyId, () => []).add(data);
                    } else {
                      heads.add(data);
                    }
                  }

                  final filteredHeads = heads.where((head) {
                    final headName = (head['name'] ?? '').toString().toLowerCase();
                    final familyId = head['familyId'] ?? '';
                    final familyList = families[familyId] ?? [];

                    final headMatches = headName.contains(searchQuery.toLowerCase());
                    final familyMatches = familyList.any((member) =>
                        (member['name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase()));

                    return searchQuery.isEmpty || headMatches || familyMatches;
                  }).toList();

                  if (filteredHeads.isEmpty) {
                    return const Center(child: Text('No members yet.'));
                  }

                  return ListView.builder(
                    itemCount: filteredHeads.length,
                    itemBuilder: (context, index) {
                      final head = filteredHeads[index];
                      final familyId = head['familyId'] ?? '';
                      final headName = head['name'] ?? '';
                      final phone = head['phone'] ?? '';
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
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Delete Member',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirm Deletion'),
                                        content: const Text('Are you sure you want to delete this member?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              await _deleteMember(docId);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Member deleted')),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(head['isHidden'] == true ? Icons.visibility_off : Icons.visibility),
                                  tooltip: head['isHidden'] == true ? 'Unhide Member' : 'Hide Member',
                                  onPressed: () => _toggleHideMember(docId, head['isHidden'] ?? false),
                                ),
                              ],
                            ),
                            if (children.isNotEmpty) ...[
                              const Divider(),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Family Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              ...children.where((member) {
                                if (!showHidden && (member['isHidden'] ?? false)) return false;
                                return searchQuery.isEmpty || (member['name']?.toString().toLowerCase().contains(searchQuery) ?? false);
                              }).map((member) {
                                final memberName = member['name'] ?? '';
                                final memberPhone = member['phone'] ?? '';
                                final memberAddress = member['address'] ?? '';
                                final memberId = member['id'];

                                return ListTile(
                                  title: Text(memberName),
                                  subtitle: Text('Phone: $memberPhone\nAddress: $memberAddress'),
                                  trailing: Wrap(
                                    spacing: 12,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AddFamilyMemberScreen(
                                                familyId: familyId,
                                                memberId: memberId,
                                                existingData: member,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Confirm Deletion'),
                                              content: const Text('Are you sure you want to delete this member?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    Navigator.pop(ctx);
                                                    await _deleteMember(memberId);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Member deleted')),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(member['isHidden'] == true ? Icons.visibility_off : Icons.visibility),
                                        onPressed: () => _toggleHideMember(memberId, member['isHidden'] ?? false),
                                      ),
                                    ],
                                  ),
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
