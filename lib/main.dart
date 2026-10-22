import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supporthive1/view/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  await Hive.openBox('gameBox');
  await Hive.openBox('breathingSessions');
  await Hive.openBox('notesBox');

  
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
      home: const SplashScreen(),
    );
  }
}