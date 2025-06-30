import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewRecordsScreen extends StatefulWidget {
  const ViewRecordsScreen({super.key});

  @override
  State<ViewRecordsScreen> createState() => _ViewRecordsScreenState();
}

class _ViewRecordsScreenState extends State<ViewRecordsScreen> {
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  String selectedType = 'All';
  String selectedMember = 'All';
  DateTime? selectedDate;

  List<String> members = ['All', 'John', 'Priya', 'Abraham', 'Ruth'];

  @override
  void initState() {
    super.initState();

    // Dummy data - replace with Firestore fetch
    allTransactions = [
      {
        'member': 'John',
        'type': 'Income',
        'amount': 1000,
        'description': 'Tithe',
        'date': DateTime(2025, 6, 25),
        'event': 'Sunday Service'
      },
      {
        'member': 'Priya',
        'type': 'Expense',
        'amount': 500,
        'description': 'Snacks',
        'date': DateTime(2025, 6, 25),
        'event': 'Sunday Service'
      },
      {
        'member': 'Ruth',
        'type': 'Income',
        'amount': 800,
        'description': 'Donation',
        'date': DateTime(2025, 6, 26),
        'event': 'Special Prayer Meet'
      },
    ];

    filteredTransactions = List.from(allTransactions);
  }

  void _filterTransactions() {
    setState(() {
      filteredTransactions = allTransactions.where((txn) {
        final matchesType =
            selectedType == 'All' || txn['type'] == selectedType;
        final matchesMember =
            selectedMember == 'All' || txn['member'] == selectedMember;
        final matchesDate = selectedDate == null ||
            DateFormat('yyyy-MM-dd').format(txn['date']) ==
                DateFormat('yyyy-MM-dd').format(selectedDate!);

        return matchesType && matchesMember && matchesDate;
      }).toList();
    });
  }

  void _exportToExcel() {
    // TODO: Replace with actual Excel export using `excel` or `syncfusion_flutter_xlsio`
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exported filtered data (stub).")),
    );
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _filterTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedType = 'All';
      selectedMember = 'All';
      selectedDate = null;
      filteredTransactions = List.from(allTransactions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue,
        title: const Text('View Records',style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
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
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedType = val!;
                  _filterTransactions();
                });
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: selectedMember,
              items: members
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedMember = val!;
                  _filterTransactions();
                });
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
          leading: Icon(txn['type'] == 'Income'
              ? Icons.arrow_downward
              : Icons.arrow_upward,
              color: txn['type'] == 'Income' ? Colors.green : Colors.red),
          title: Text('${txn['member']} - ₹${txn['amount']}'),
          subtitle: Text(
              '${txn['description']} • ${txn['event']} • ${DateFormat('yyyy-MM-dd').format(txn['date'])}'),
          trailing: Text(txn['type'],
              style: TextStyle(
                  color: txn['type'] == 'Income' ? Colors.green : Colors.red)),
        );
      },
    );
  }
}
