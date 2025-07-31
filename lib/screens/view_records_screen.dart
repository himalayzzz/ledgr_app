import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgr/export_excel.dart';

class ViewRecordsScreen extends StatefulWidget {
  const ViewRecordsScreen({super.key});

  @override
  State<ViewRecordsScreen> createState() => _ViewRecordsScreenState();
}

class _ViewRecordsScreenState extends State<ViewRecordsScreen> {
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  String? selectedMember;
  String? selectedType;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedEvent;

  @override
  void initState() {
    super.initState();
    fetchAllTransactions();
  }

  Future<void> fetchAllTransactions() async {
    List<Map<String, dynamic>> transactionsList = [];

    final eventsSnapshot = await FirebaseFirestore.instance.collection('events').get();

    for (var eventDoc in eventsSnapshot.docs) {
      final eventData = eventDoc.data();
      final eventId = eventDoc.id;
      final eventTitle = eventData['title'] ?? 'Untitled';
      final eventDate = (eventData['date'] as Timestamp).toDate();
      final eventType = eventData['type'] ?? 'main';

      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection('transactions')
          .get();

      for (var txn in transactionsSnapshot.docs) {
        final txnData = txn.data();
        txnData['eventTitle'] = eventTitle;
        txnData['eventDate'] = eventDate;
        txnData['eventType'] = eventType;
        txnData['timestamp'] = txnData['timestamp']; // Add the original timestamp
        txnData['id'] = txn.id;
        txnData['eventId'] = eventId;
        
        // Add main event info for sub events
        if (eventType == 'sub' && eventData['mainEventTitle'] != null) {
          txnData['mainEventTitle'] = eventData['mainEventTitle'];
          txnData['eventTitle'] = '${eventData['mainEventTitle']} - $eventTitle';
        }
        
        transactionsList.add(txnData);
      }
    }

    setState(() {
      allTransactions = transactionsList;
      applyFilters();
    });
  }

  void applyFilters() {
    setState(() {
      filteredTransactions = allTransactions.where((txn) {
        final txnDate = txn['eventDate'] as DateTime;
        final matchesMember = selectedMember == null || txn['member'] == selectedMember;
        final matchesType = selectedType == null || txn['type'] == selectedType;
        final matchesEvent = selectedEvent == null || txn['eventTitle'] == selectedEvent;
        final matchesStart = startDate == null || !txnDate.isBefore(startDate!);
        final matchesEnd = endDate == null || !txnDate.isAfter(endDate!);
        return matchesMember && matchesType && matchesEvent && matchesStart && matchesEnd;
      }).toList();
    });
  }

  void clearFilters() {
    setState(() {
      selectedMember = null;
      selectedType = null;
      startDate = null;
      endDate = null;
      selectedEvent = null;
      applyFilters();
    });
  }

  Future<void> selectDate(BuildContext context, bool isStart) async {
    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (newDate != null) {
      setState(() {
        if (isStart) {
          startDate = newDate;
        } else {
          endDate = newDate;
        }
        applyFilters();
      });
    }
  }

  Future<void> _exportData() async {
    await exportFilteredTransactionsToExcel(context, filteredTransactions);
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onTap,
    String? selectedValue,
    IconData? icon,
    bool isDateFilter = false,
  }) {
    return ActionChip(
      label: Text(
        selectedValue ?? label,
        style: TextStyle(
          color: selectedValue != null || isDateFilter ? Colors.white : const Color.fromARGB(255, 115, 157, 219),
          fontWeight: FontWeight.bold,
        ),
      ),
      avatar: icon != null ? Icon(icon, color: selectedValue != null || isDateFilter ? Colors.white : Colors.blueGrey[700]) : null,
      backgroundColor: selectedValue != null || isDateFilter ? Colors.cyan : Colors.blueGrey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selectedValue != null || isDateFilter ? Colors.cyan : (Colors.blueGrey[200] ?? Colors.grey)),
      ),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final allMembers = allTransactions.map((e) => e['member']).toSet().toList();
    final allEvents = allTransactions.map((e) => e['eventTitle']).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('St. Jospeh JSOC- View Records', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportData,
            tooltip: 'Export to Excel',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      label: "Filter by Member",
                      icon: Icons.person,
                      selectedValue: selectedMember,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true, // This is key for full height scrolling
                          builder: (BuildContext context) {
                            // Using a DraggableScrollableSheet for better control over sheet height
                            return DraggableScrollableSheet(
                              initialChildSize: 0.5, // Start at 50% of screen height
                              minChildSize: 0.25, // Can shrink to 25%
                              maxChildSize: 0.9,  // Can expand to 90%
                              expand: false, // Don't expand to full screen initially
                              builder: (BuildContext context, ScrollController scrollController) {
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Select Member', style: Theme.of(context).textTheme.headlineSmall),
                                    ),
                                    Divider(),
                                    Expanded(
                                      child: ListView.builder(
                                        controller: scrollController, // Pass the scroll controller
                                        itemCount: allMembers.length + 1, // +1 for "Clear Filter"
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return ListTile(
                                              title: const Text('Clear Filter', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 231, 54, 41))),
                                              onTap: () {
                                                setState(() {
                                                  selectedMember = null;
                                                  applyFilters();
                                                });
                                                Navigator.pop(context);
                                              },
                                            );
                                          }
                                          final memberStr = allMembers[index - 1]?.toString() ?? "";
                                          return ListTile(
                                            title: Text(memberStr),
                                            onTap: () {
                                              setState(() {
                                                selectedMember = memberStr;
                                                applyFilters();
                                              });
                                              Navigator.pop(context);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    _buildFilterChip(
                      label: "Filter by Type",
                      icon: Icons.category,
                      selectedValue: selectedType,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true, // This is key for full height scrolling
                          builder: (BuildContext context) {
                            return DraggableScrollableSheet(
                              initialChildSize: 0.4, // Adjust as needed
                              minChildSize: 0.2,
                              maxChildSize: 0.7,
                              expand: false,
                              builder: (BuildContext context, ScrollController scrollController) {
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Select Type', style: Theme.of(context).textTheme.headlineSmall),
                                    ),
                                    Divider(),
                                    Expanded(
                                      child: ListView.builder(
                                        controller: scrollController,
                                        itemCount: ['Income', 'Expense'].length + 1, // +1 for "Clear Filter"
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return ListTile(
                                              title: const Text('Clear Filter', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                              onTap: () {
                                                setState(() {
                                                  selectedType = null;
                                                  applyFilters();
                                                });
                                                Navigator.pop(context);
                                              },
                                            );
                                          }
                                          final type = ['Income', 'Expense'][index - 1];
                                          return ListTile(
                                            title: Text(type),
                                            onTap: () {
                                              setState(() {
                                                selectedType = type;
                                                applyFilters();
                                              });
                                              Navigator.pop(context);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    _buildFilterChip(
                      label: "Filter by Event",
                      icon: Icons.event,
                      selectedValue: selectedEvent,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true, // This is key for full height scrolling
                          builder: (BuildContext context) {
                            return DraggableScrollableSheet(
                              initialChildSize: 0.5, // Adjust as needed
                              minChildSize: 0.25,
                              maxChildSize: 0.9,
                              expand: false,
                              builder: (BuildContext context, ScrollController scrollController) {
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Select Event', style: Theme.of(context).textTheme.headlineSmall),
                                    ),
                                    Divider(),
                                    Expanded(
                                      child: ListView.builder(
                                        controller: scrollController,
                                        itemCount: allEvents.length + 1, // +1 for "Clear Filter"
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return ListTile(
                                              title: const Text('Clear Filter', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                              onTap: () {
                                                setState(() {
                                                  selectedEvent = null;
                                                  applyFilters();
                                                });
                                                Navigator.pop(context);
                                              },
                                            );
                                          }
                                          final eventStr = allEvents[index - 1]?.toString() ?? "";
                                          return ListTile(
                                            title: Text(eventStr),
                                            onTap: () {
                                              setState(() {
                                                selectedEvent = eventStr;
                                                applyFilters();
                                              });
                                              Navigator.pop(context);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    _buildFilterChip(
                      label: "Start Date",
                      icon: Icons.calendar_today,
                      selectedValue: startDate != null ? dateFormat.format(startDate!) : null,
                      onTap: () => selectDate(context, true),
                      isDateFilter: startDate != null,
                    ),
                    _buildFilterChip(
                      label: "End Date",
                      icon: Icons.calendar_today,
                      selectedValue: endDate != null ? dateFormat.format(endDate!) : null,
                      onTap: () => selectDate(context, false),
                      isDateFilter: endDate != null,
                    ),
                    ActionChip(
                      label: const Text("Clear All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      avatar: const Icon(Icons.clear_all, color: Colors.white),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.orangeAccent),
                      ),
                      onPressed: clearFilters,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 12, endIndent: 12),
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "No records found for the selected filters.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final txn = filteredTransactions[index];
                      final isIncome = txn['type'] == 'Income';
                      final eventType = txn['eventType'] ?? 'main';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: isIncome ? Colors.green[50] : Colors.red[50],
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome ? Colors.green : Colors.red,
                            child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${txn['type']}: £${txn['amount']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? Colors.green[900] : Colors.red[900],
                                  ),
                                ),
                              ),
                              if (eventType == 'sub')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('SUB',
                                      style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Member: ${txn['member'] ?? 'N/A'}", style: const TextStyle(fontSize: 13)),
                              Text("Description: ${txn['description'] ?? 'N/A'}", style: const TextStyle(fontSize: 13)),
                              Text("Event: ${txn['eventTitle'] ?? 'N/A'}", style: const TextStyle(fontSize: 13)),
                              Text("Date: ${dateFormat.format(txn['eventDate'])}", style: const TextStyle(fontSize: 13)),
                              if (txn['lastModifiedBy'] != null)
                                Text(
                                  "Modified by: ${txn['lastModifiedBy']}",
                                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}