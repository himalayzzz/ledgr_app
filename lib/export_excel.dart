import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart'; // Import for date formatting

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

  final headers = ['Slno', 'Member', 'Amount', 'Type', 'Description', 'Date & Time'];
  sheet.appendRow(headers);

  final CellStyle headerStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Arial),
  );
  for (int col = 0; col < headers.length; col++) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
        .cellStyle = headerStyle;
  }

  final dateFormat = DateFormat('dd-MM-yyyy HH:mm:ss');

  int slno = 1; // Initialize serial number for this export
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    sheet.appendRow([
      slno++, // Increment slno for each row
      data['member'] ?? '',
      data['amount'] ?? 0,
      data['type'] ?? '',
      data['description'] ?? '',
      timestamp != null ? dateFormat.format(timestamp) : 'Unknown',
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

  // Adjusted headers to match requirements and data availability
  final headers = ['Slno', 'Member', 'Amount', 'Type', 'Description', 'Event Title', 'Event Date', 'Timestamp'];
  sheet.appendRow(headers);

  final CellStyle headerStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Arial),
  );
  for (int col = 0; col < headers.length; col++) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
        .cellStyle = headerStyle;
  }

  final eventDateFormat = DateFormat('dd-MM-yyyy');
  final timestampFormat = DateFormat('dd-MM-yyyy HH:mm:ss');

  int slno = 1;
  for (final txn in filteredTransactions) {
    final eventTitle = txn['eventTitle'] ?? '';
    final eventDate = (txn['eventDate'] is Timestamp)
        ? (txn['eventDate'] as Timestamp).toDate()
        : (txn['eventDate'] is DateTime)
            ? txn['eventDate'] as DateTime
            : null;

    final timestamp = (txn['timestamp'] is Timestamp)
        ? (txn['timestamp'] as Timestamp).toDate()
        : (txn['timestamp'] is DateTime)
            ? txn['timestamp'] as DateTime
            : null;

    sheet.appendRow([
      slno++,
      txn['member'] ?? '',
      txn['amount'] ?? 0,
      txn['type'] ?? '',
      txn['description'] ?? '',
      eventTitle,
      eventDate != null ? eventDateFormat.format(eventDate) : 'Unknown',
      timestamp != null ? timestampFormat.format(timestamp) : 'Unknown',
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

// Export all members to Excel


Future<void> exportMembersToExcel(BuildContext context, List<Map<String, dynamic>> members) async {
  if (members.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No members to export.')),
    );
    return;
  }

  try {
    final Excel excel = Excel.createExcel();
    const sheetName = 'Members';
    final Sheet? sheet = excel[sheetName];
if (sheet == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not create Excel sheet.')),
  );
  return;
}

    // Add headers
    final headers = ['Sl. No.', 'Name', 'Phone', 'Address', 'Role'];
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = headers[i];
    }

    // Add member rows
    for (int i = 0; i < members.length; i++) {
      final member = members[i];
      final rowIndex = i + 1;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = '${i + 1}'; // Sl. No.
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = member['name'] ?? '';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = member['phone'] ?? '';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = member['address'] ?? '';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = (member['isFamily'] == true) ? 'Family Member' : 'Main Member';
    }

    final List<int>? bytes = excel.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to encode Excel file.')),
      );
      return;
    }

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'members_data.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel downloaded successfully.')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error exporting Excel: $e')),
    );
  }
}
