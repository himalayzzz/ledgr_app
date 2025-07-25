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
  List<String> events = ['All'];

  String selectedType = 'All';
  String selectedMember = 'All';
  String selectedEvent = 'All';
  DateTime? startDate;
  DateTime? endDate;

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
      eventNames[doc.id] = doc['title'];
      events.add(doc['title']);
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
        'event': eventTitle,
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
        final matchesEvent = selectedEvent == 'All' || txn['event'] == selectedEvent;
        final matchesDate = (startDate == null || txn['date'].isAfter(startDate!.subtract(const Duration(days: 1)))) &&
                            (endDate == null || txn['date'].isBefore(endDate!.add(const Duration(days: 1))));

        return matchesType && matchesMember && matchesEvent && matchesDate;
      }).toList();
      calculateTotals();
    });
  }

  void _exportToExcel() async {
    await exportFilteredTransactionsToExcel(context, filteredTransactions);
  }

  void _pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      startDate = picked;
      _filterTransactions();
    }
  }

  void _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      endDate = picked;
      _filterTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedType = 'All';
      selectedMember = 'All';
      selectedEvent = 'All';
      startDate = null;
      endDate = null;
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
            icon: const Icon(Icons.download),
            onPressed: _exportToExcel,
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
            DropdownButton<String>(
              value: selectedEvent,
              items: events.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                selectedEvent = val!;
                _filterTransactions();
              },
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(startDate == null ? 'Start Date' : DateFormat('yyyy-MM-dd').format(startDate!)),
              onPressed: _pickStartDate,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(endDate == null ? 'End Date' : DateFormat('yyyy-MM-dd').format(endDate!)),
              onPressed: _pickEndDate,
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
