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
  List<String> members = ['All'];

  String selectedType = 'All';
  String selectedMember = 'All';
  DateTime? selectedDate;

  double totalIncome = 0;
  double totalExpense = 0;
  Map<String, String> eventNames = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

Future<void> fetchData() async {
  // Fetch members
  final memberSnapshot = await FirebaseFirestore.instance.collection('members').get();
  members.addAll(memberSnapshot.docs.map((doc) => doc['name'].toString()));

  // Fetch events
  final eventSnapshot = await FirebaseFirestore.instance.collection('events').get();
  for (var doc in eventSnapshot.docs) {
    eventNames[doc.id] = doc['title']; // Assuming event has a 'title' field
  }

  // Fetch transactions across all events
  final transactionSnapshot = await FirebaseFirestore.instance.collectionGroup('transactions').get();

  allTransactions = transactionSnapshot.docs.map((doc) {
    final data = doc.data();
    final eventId = doc.reference.parent.parent?.id ?? 'Unknown';
    final eventTitle = eventNames[eventId] ?? 'Unknown Event';

    return {
      'member': data['member'],
      'type': data['type'],
      'amount': data['amount'],
      'description': data['description'],
      'date': (data['timestamp'] as Timestamp).toDate(),
      'event': eventTitle, // Use title instead of ID
    };
  }).toList();

  filteredTransactions = List.from(allTransactions);
  calculateTotals();
  setState(() {});
}


  void calculateTotals() {
    totalIncome = 0;
    totalExpense = 0;

    for (var txn in filteredTransactions) {
      if (txn['type'] == 'Income') {
        totalIncome += txn['amount'];
      } else if (txn['type'] == 'Expense') {
        totalExpense += txn['amount'];
      }
    }
  }

  void _filterTransactions() {
    setState(() {
      filteredTransactions = allTransactions.where((txn) {
        final matchesType = selectedType == 'All' || txn['type'] == selectedType;
        final matchesMember = selectedMember == 'All' || txn['member'] == selectedMember;
        final matchesDate = selectedDate == null ||
            DateFormat('yyyy-MM-dd').format(txn['date']) ==
                DateFormat('yyyy-MM-dd').format(selectedDate!);
        return matchesType && matchesMember && matchesDate;
      }).toList();
      calculateTotals();
    });
  }

void _exportToExcel() async {
  await exportFilteredTransactionsToExcel(context, filteredTransactions);
}
  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      selectedDate = picked;
      _filterTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedType = 'All';
      selectedMember = 'All';
      selectedDate = null;
      filteredTransactions = List.from(allTransactions);
      calculateTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('View Records', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
  icon: Icon(Icons.download),
  onPressed: () async {
    await exportFilteredTransactionsToExcel(context, filteredTransactions);
  },
),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(),
          _buildTotals(),
          const Divider(),
          Expanded(child: _buildTransactionList())
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            DropdownButton<String>(
              value: selectedType,
              items: ['All', 'Income', 'Expense']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (val) {
                selectedType = val!;
                _filterTransactions();
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: selectedMember,
              items: members.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) {
                selectedMember = val!;
                _filterTransactions();
              },
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(selectedDate == null
                  ? 'Pick Date'
                  : DateFormat('yyyy-MM-dd').format(selectedDate!)),
              onPressed: _pickDate,
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTotals() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Income: ₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          Text('Expense: ₹${totalExpense.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (filteredTransactions.isEmpty) {
      return const Center(child: Text('No records found.'));
    }

    return ListView.separated(
      itemCount: filteredTransactions.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final txn = filteredTransactions[index];
        return ListTile(
          leading: Icon(
            txn['type'] == 'Income' ? Icons.arrow_downward : Icons.arrow_upward,
            color: txn['type'] == 'Income' ? Colors.green : Colors.red,
          ),
          title: Text('${txn['member']} - ₹${txn['amount']}'),
          subtitle: Text('${txn['description']} • ${txn['event']} • ${DateFormat('yyyy-MM-dd').format(txn['date'])}'),
          trailing: Text(
            txn['type'],
            style: TextStyle(
              color: txn['type'] == 'Income' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}