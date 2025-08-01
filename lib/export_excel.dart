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

/// Export all members to Excel with proper family structure
Future<void> exportMembersToExcel(BuildContext context, List<Map<String, dynamic>> members) async {
  if (members.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No members to export.')),
    );
    return;
  }

  try {
    final Excel excel = Excel.createExcel();
    
    // Remove the default 'Sheet1' that gets created automatically
    excel.delete('Sheet1');
    
    // Create our custom sheet
    const sheetName = 'Members';
    excel[sheetName]; // This creates the sheet
    final Sheet sheet = excel[sheetName];

    // Add headers
    final headers = ['Sl. No.', 'Name', 'Phone', 'Address', 'Role'];
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = headers[i];
    }

    // Style headers
    final CellStyle headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
    );
    for (int col = 0; col < headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    // Group members by family
    final Map<String, List<Map<String, dynamic>>> families = {};
    final List<Map<String, dynamic>> independentMembers = [];

    for (final member in members) {
      final isFamily = member['isFamily'] ?? false;
      final familyId = member['familyId'] ?? '';

      if (isFamily && familyId.isNotEmpty) {
        families.putIfAbsent(familyId, () => []).add(member);
      } else {
        independentMembers.add(member);
      }
    }

    // Sort independent members by name
    independentMembers.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    int rowIndex = 1;
    int slno = 1;

    // Add independent members first
    for (final member in independentMembers) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = slno++;
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
          .value = 'Main Member';
      
      rowIndex++;

      // Add family members if this is a family head
      final familyId = member['familyId'] ?? '';
      if (familyId.isNotEmpty && families.containsKey(familyId)) {
        final familyMembers = families[familyId]!;
        familyMembers.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        
        for (final familyMember in familyMembers) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
              .value = slno++;
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
              .value = '  ${familyMember['name'] ?? ''}'; // Indent family members
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
              .value = familyMember['phone'] ?? '';
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
              .value = familyMember['address'] ?? '';
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
              .value = 'Family Member';
          
          rowIndex++;
        }
        
        // Remove this family from the map so we don't process it again
        families.remove(familyId);
      }
    }

    // Add any remaining family members that weren't linked to a head
    for (final familyId in families.keys) {
      final familyMembers = families[familyId]!;
      familyMembers.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      
      for (final familyMember in familyMembers) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = slno++;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = familyMember['name'] ?? '';
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = familyMember['phone'] ?? '';
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = familyMember['address'] ?? '';
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = 'Family Member';
        
        rowIndex++;
      }
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