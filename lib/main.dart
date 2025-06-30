
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ledgr/firebase_options.dart';
import 'package:ledgr/screens/accounts_screen.dart';
import 'package:ledgr/screens/dashboard_screen.dart';
import 'package:ledgr/screens/event_detail_screen.dart';
import 'package:ledgr/screens/login_screen.dart';
import 'package:ledgr/screens/add_member_screen.dart';
import 'package:ledgr/screens/view_records_screen.dart';

void main()  async{
 //  WidgetsFlutterBinding.ensureInitialized();
 //  await Firebase.initializeApp(
 //    options: DefaultFirebaseOptions.currentPlatform,
 //  ); // Initialize Firebase
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),

      // Define routes 
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
