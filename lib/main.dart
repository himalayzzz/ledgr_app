// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/accounts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/add_member_screen.dart';
import 'screens/view_records_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          try {
            return LoginScreen();
          } catch (e, stack) {
            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text('❌ Error in LoginScreen:\n$e\n\n$stack'),
                ),
              ),
            );
          }
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/add-member': (context) => const AddMemberScreen(),
        '/accounts': (context) => const AccountsScreen(),
        '/event-detail': (context) => const EventDetailScreen(
              eventId: 'example123',
              eventTitle: 'Sample Event',
              eventDate: 'June 30, 2025',
            ),
        '/view-records': (context) => const ViewRecordsScreen(),
      },
    );
  }
}