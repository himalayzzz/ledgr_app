import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

/// Shared download utility
void _downloadExcel(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Export transactions for a single event from Firestore
Future<void> exportEventTransactionsToExcel(
    BuildContext context, String eventId, String eventTitle) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .collection('transactions')
      .orderBy('timestamp')
      .get();

  final Excel excel = Excel.createExcel();
  final Sheet sheet = excel['Sheet1'];

  sheet.appendRow(['Member', 'Amount', 'Type', 'Description', 'Timestamp']);

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    sheet.appendRow([
      data['member'] ?? '',
      data['amount']?.toString() ?? '0',
      data['type'] ?? '',
      data['description'] ?? '',
      timestamp?.toString() ?? 'Unknown',
    ]);
  }

  final List<int>? fileBytes = excel.encode();
  if (fileBytes != null) {
    _downloadExcel(Uint8List.fromList(fileBytes), "$eventTitle.xlsx");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel file exported.')),
    );
  }
}

/// Export filtered transactions passed from the UI
Future<void> exportFilteredTransactionsToExcel(
    BuildContext context, List<Map<String, dynamic>> filteredTransactions) async {
  if (filteredTransactions.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No data to export')),
    );
    return;
  }

  final Excel excel = Excel.createExcel();
  final Sheet sheet = excel['Sheet1'];

  sheet.appendRow([
    'Member',
    'Amount',
    'Type',
    'Description',
    'Event',
    'Date',
  ]);

  for (final txn in filteredTransactions) {
    sheet.appendRow([
      txn['member'] ?? '',
      txn['amount']?.toString() ?? '0',
      txn['type'] ?? '',
      txn['description'] ?? '',
      txn['event'] ?? '',
      txn['date']?.toString() ?? 'Unknown',
    ]);
  }

  final List<int>? fileBytes = excel.encode();
  if (fileBytes != null) {
    _downloadExcel(Uint8List.fromList(fileBytes), "Filtered_Transactions.xlsx");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel file exported.')),
    );
  }
}
