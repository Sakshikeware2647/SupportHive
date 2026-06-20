import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supporthive1/view/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 1. Load ENV (must be first)
  await dotenv.load(fileName: ".env");

  // ✅ 2. Init Hive
  await Hive.initFlutter();
  await Hive.openBox('notesBox');

  // ✅ 3. Init Firebase safely with try/catch
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAZmVkQwBE2m9bltqdsec-Pzb7QzqeafR0",
        appId: "1:409410953894:android:bcd95f1304e75573990a67",
        messagingSenderId: "409410953894",
        projectId: "supporthive-d8c35",
        storageBucket: "supporthive-d8c35.appspot.com",
      ),
    );
  } catch (e) {
    // Already initialized — safe to ignore
    debugPrint('Firebase already initialized: $e');
  }

  runApp(const SupportHiveApp());
}

class SupportHiveApp extends StatelessWidget {
  const SupportHiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SupportHive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        fontFamily: 'Roboto',
      ),
      home: const WelcomeScreen(),
    );
  }
}