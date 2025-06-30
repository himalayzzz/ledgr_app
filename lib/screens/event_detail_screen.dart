import 'package:flutter/material.dart';
// Import Firestore and Excel logic as needed

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
  List<String> memberList = ['John', 'Priya', 'Abraham', 'Ruth'];
  List<Map<String, dynamic>> transactions = [];

  String filterType = 'All'; // All, Income, Expense

  @override
  void initState() {
    super.initState();
    // TODO: Load transactions from Firestore
    for (var member in memberList) {
      transactions.add({
        'member': member,
        'amount': '',
        'type': 'Income',
        'description': '',
        'timestamp': DateTime.now(),
      });
    }
  }

  void _exportData() {
    // TODO: Implement using `excel` package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported (stub). Implement with Excel logic.')),
    );
  }

  void _applyFilter(String type) {
    setState(() {
      filterType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = transactions.where((row) {
      if (filterType == 'All') return true;
      return row['type'].toString().toLowerCase() == filterType.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue,
        title: Text(widget.eventTitle, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        actions: [
          PopupMenuButton<String>(
            onSelected: _applyFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Income', child: Text('Income')),
              const PopupMenuItem(value: 'Expense', child: Text('Expense')),
            ],
            icon: const Icon(Icons.filter_alt),
          ),
          IconButton(
            onPressed: _exportData,
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
          ),
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
      ],
    ),
    Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        onPressed: () {
          setState(() {
            transactions.add({
              'member': '',
              'amount': '',
              'type': 'Income',
              'description': '',
              'timestamp': DateTime.now(),
              'isCustom': true,
            });
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        tooltip: 'Add Miscellaneous Entry',
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
        0: FlexColumnWidth(2), // Member
        1: FlexColumnWidth(2), // Amount
        2: FlexColumnWidth(2), // Type
        3: FlexColumnWidth(3), // Description
        4: FlexColumnWidth(2), // Actions
      },
      children: [
        _buildHeaderRow(),
        ...data.map((row) => _buildDataRow(row)).toList(),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return const TableRow(
      decoration: BoxDecoration(color: Color.fromARGB(255, 228, 236, 250)),
      children: [
        Padding(padding: EdgeInsets.all(8), child: Text('Member')),
        Padding(padding: EdgeInsets.all(8), child: Text('Amount')),
        Padding(padding: EdgeInsets.all(8), child: Text('Type')),
        Padding(padding: EdgeInsets.all(8), child: Text('Description')),
        Padding(padding: EdgeInsets.all(8), child: Text('Actions')),
      ],
    );
  }

  TableRow _buildDataRow(Map<String, dynamic> row) {
  final amountController = TextEditingController(text: row['amount'].toString());
  final descController = TextEditingController(text: row['description']);
  final memberController = TextEditingController(text: row['member']);

  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: row['isCustom'] == true
            ? TextField(
                controller: memberController,
                onChanged: (val) => row['member'] = val,
                decoration: const InputDecoration(
                  hintText: 'Member',
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
          decoration: const InputDecoration(border: InputBorder.none),
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
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.green),
              onPressed: () {
                // Optional: pop a dialog or just use the editable text
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  transactions.remove(row);
                });
              },
            ),
          ],
        ),
      ),
    ],
  );
}
}
