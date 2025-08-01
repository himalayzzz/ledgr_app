import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgr/screens/add_family_screen.dart';
import 'package:ledgr/screens/add_member_screen.dart';
import 'package:ledgr/screens/accounts_screen.dart';
import 'package:ledgr/screens/view_records_screen.dart';
import 'package:ledgr/export_excel.dart';

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

  String formatName(String name) {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  // Fixed function to prepare data for export
  List<Map<String, dynamic>> _prepareMembersForExport(List<DocumentSnapshot> docs) {
    final List<Map<String, dynamic>> allMembers = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final id = doc.id;
      final nameRaw = (data['name'] ?? '').toString();
      final formattedName = formatName(nameRaw);
      final isHidden = data['isHidden'] ?? false;

      // Skip hidden members if not showing them
      if (!showHidden && isHidden) continue;

      // Add formatted data to the list
      allMembers.add({
        'id': id,
        'name': formattedName,
        'phone': data['phone'] ?? '',
        'address': data['address'] ?? '',
        'isFamily': data['isFamily'] ?? false,
        'familyId': data['familyId'] ?? '',
        'isHidden': isHidden,
      });
    }

    return allMembers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F9),
      appBar: AppBar(
        title: const Text('Ledgr Dashboard- St. Joseph JSOC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(showHidden ? Icons.visibility_off : Icons.visibility),
            tooltip: showHidden ? 'Hide Hidden Members' : 'Show Hidden Members',
            onPressed: () => setState(() => showHidden = !showHidden),
          ),
          // Fixed download button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Members Data',
            onPressed: () async {
              try {
                final snapshot = await membersCol.get();
                final membersToExport = _prepareMembersForExport(snapshot.docs);
                
                if (membersToExport.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No members to export')),
                  );
                  return;
                }
                
                await exportMembersToExcel(context, membersToExport);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error exporting data: $e')),
                );
              }
            },
          ),
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
                stream: membersCol.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  final heads = <Map<String, dynamic>>[];
                  final families = <String, List<Map<String, dynamic>>>{};

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    final nameRaw = (data['name'] ?? '').toString();
                    final formattedName = formatName(nameRaw);
                    final isHidden = data['isHidden'] ?? false;

                    if (!showHidden && isHidden) continue;

                    final isFamily = data['isFamily'] ?? false;
                    final familyId = data['familyId'] ?? '';
                    data['id'] = id;
                    data['name'] = formattedName;

                    if (isFamily && familyId.isNotEmpty) {
                      families.putIfAbsent(familyId, () => []).add(data);
                    } else {
                      heads.add(data);
                    }
                  }

                  heads.sort((a, b) => a['name'].compareTo(b['name']));

                  final filteredHeads = heads.where((head) {
                    final headName = (head['name'] ?? '').toString().toLowerCase();
                    final familyId = head['familyId'] ?? '';
                    final familyList = families[familyId] ?? [];

                    final headMatches = headName.contains(searchQuery);
                    final familyMatches = familyList.any((member) =>
                        (member['name'] ?? '').toString().toLowerCase().contains(searchQuery));

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
                          title: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  headName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
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
                                        content: Text('Are you sure you want to delete $headName?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Are you sure?'),
                                                  content: const Text('This action cannot be undone.'),
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
                                final familyMemberIndex = children.indexOf(member) + 1;

                                return ListTile(
                                  leading: Container(
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}.$familyMemberIndex',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
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
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    showDialog(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text('Are you really sure?'),
                                                        content: const Text('This action cannot be undone.'),
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