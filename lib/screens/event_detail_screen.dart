import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ledgr/export_excel.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String eventDate;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<Map<String, dynamic>> transactions = [];
  String filterType = 'All';

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('transactions')
        .orderBy('timestamp')
        .get();

    setState(() {
      transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'member': data['member'] ?? '',
          'amount': data['amount'].toString(),
          'type': data['type'] ?? 'Income',
          'description': data['description'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
          'lastModifiedBy': data['lastModifiedBy'] ?? '',
          'fromFirestore': true,
        };
      }).toList();
    });
  }

  void _applyFilter(String type) {
    setState(() {
      filterType = type;
    });
  }

  void _addEmptyRow() {
    setState(() {
      transactions.add({
        'member': '',
        'amount': '',
        'type': 'Income',
        'description': '',
        'timestamp': DateTime.now(),
        'isCustom': true,
        'lastModifiedBy': '',
      });
    });
  }

  void _exportData() async {
    await exportEventTransactionsToExcel(context, widget.eventId, widget.eventTitle);
  }

  Map<String, double> _calculateTotals(List<Map<String, dynamic>> list) {
    double income = 0;
    double expense = 0;

    for (var row in list) {
      double amt = double.tryParse(row['amount'].toString()) ?? 0;
      if (row['type'] == 'Income') {
        income += amt;
      } else if (row['type'] == 'Expense') {
        expense += amt;
      }
    }

    return {'income': income, 'expense': expense};
  }

  @override
  Widget build(BuildContext context) {
    final filtered = transactions.where((row) {
      if (filterType == 'All') return true;
      return row['type'].toString().toLowerCase() == filterType.toLowerCase();
    }).toList();

    final totals = _calculateTotals(filtered);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(widget.eventTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            onSelected: _applyFilter,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Income', child: Text('Income')),
              PopupMenuItem(value: 'Expense', child: Text('Expense')),
            ],
            icon: const Icon(Icons.filter_alt),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
            tooltip: 'Export to Excel',
          )
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Event Date: ${widget.eventDate}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              _buildTable(filtered),
              const SizedBox(height: 16),
              _buildTotalSummary(totals),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _addEmptyRow,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
              tooltip: 'Add Entry',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> data) {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(1), // Sl. No.
        1: FlexColumnWidth(2), // Member/Source
        2: FlexColumnWidth(2), // Amount
        3: FlexColumnWidth(1.5), // Type
        4: FlexColumnWidth(2.5), // Description
        5: FlexColumnWidth(2), // Last Modified By
        6: FlexColumnWidth(2), // Actions
      },
      children: [
        _buildHeaderRow(),
        for (int i = 0; i < data.length; i++) _buildDataRow(i + 1, data[i]),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return const TableRow(
      decoration: BoxDecoration(color: Color.fromARGB(255, 228, 236, 250)),
      children: [
        Padding(padding: EdgeInsets.all(8), child: Text('Sl. No.', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text('Member/Source', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text('Last Modified By', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  TableRow _buildDataRow(int index, Map<String, dynamic> row) {
    final amountController = TextEditingController(text: row['amount'].toString());
    final descController = TextEditingController(text: row['description']);
    final memberController = TextEditingController(text: row['member']);

    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text('$index')),
        Padding(
          padding: const EdgeInsets.all(8),
          child: row['isCustom'] == true
              ? TextField(
                  controller: memberController,
                  onChanged: (val) => row['member'] = val,
                  decoration: const InputDecoration(
                    hintText: 'Member/Source',
                    border: InputBorder.none,
                  ),
                )
              : Text(row['member']),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            onChanged: (val) => row['amount'] = val,
            decoration: const InputDecoration(
              prefixText: '£ ',
              border: InputBorder.none,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: DropdownButton<String>(
            value: row['type'],
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'Income', child: Text('Income')),
              DropdownMenuItem(value: 'Expense', child: Text('Expense')),
            ],
            onChanged: (val) {
              setState(() {
                row['type'] = val!;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: descController,
            onChanged: (val) => row['description'] = val,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            row['lastModifiedBy'] ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.green),
                onPressed: () async {
                  final ref = FirebaseFirestore.instance
                      .collection('events')
                      .doc(widget.eventId)
                      .collection('transactions');

                  if (row['fromFirestore'] == true) {
                    await ref.doc(row['id']).update({
                      'member': row['member'],
                      'amount': double.tryParse(row['amount'].toString()) ?? 0,
                      'type': row['type'],
                      'description': row['description'],
                      'timestamp': Timestamp.now(),
                      'eventId': widget.eventId,
                      'eventTitle': widget.eventTitle,
                      'eventDate': widget.eventDate,
                    });
                  } else {
                    final doc = await ref.add({
                      'member': row['member'],
                      'amount': double.tryParse(row['amount'].toString()) ?? 0,
                      'type': row['type'],
                      'description': row['description'],
                      'timestamp': Timestamp.now(),
                      'eventId': widget.eventId,
                      'eventTitle': widget.eventTitle,
                      'eventDate': widget.eventDate,
                    });
                    setState(() {
                      row['id'] = doc.id;
                      row['fromFirestore'] = true;
                    });
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved successfully')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Deletion?'),
                      content: const Text('Do you want to delete this entry?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final sure = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Are you sure?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
                        ],
                      ),
                    );

                    if (sure == true) {
                      if (row['fromFirestore'] == true) {
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(widget.eventId)
                            .collection('transactions')
                            .doc(row['id'])
                            .delete();
                      }
                      setState(() {
                        transactions.remove(row);
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSummary(Map<String, double> totals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1),
        Text('Total Income: £${totals['income']?.toStringAsFixed(2) ?? '0'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('Total Expense: £${totals['expense']?.toStringAsFixed(2) ?? '0'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}