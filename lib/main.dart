import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {

    await Firebase.initializeApp(
      
      options:  const FirebaseOptions (
  apiKey: "AIzaSyBnMm2CPLXzzjF7opHsEq-y4nLESELQQpM",
  authDomain: "redes-e-infraestrutura-6a397.firebaseapp.com",
  projectId: "redes-e-infraestrutura-6a397",
  storageBucket: "redes-e-infraestrutura-6a397.firebasestorage.app",
  messagingSenderId: "678497065655",
  appId: "1:678497065655:web:e6aa3f65649bd96a660b32"
      )
);
  
  } catch (_) {
  }
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Redes Infraestrutura',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005A83),
          primary: const Color(0xFF005A83),
          secondary: const Color(0xFFFF8A00),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFD7DFE8)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
