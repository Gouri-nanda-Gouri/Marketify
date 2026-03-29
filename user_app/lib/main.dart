import 'package:flutter/material.dart';
import 'package:user_app/addproduct.dart';
import 'package:user_app/homescreen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/login.dart';
import 'package:user_app/signin.dart';
import 'package:user_app/theme.dart'; // Implemented new theme

Future<void> main() async {
  await Supabase.initialize(
       url: 'https://jhaqkfxtixmoxhvipult.supabase.co',
    anonKey: 'sb_publishable_CFHSwkELXkpWb7mKQSiVlg_h5ZsSyU0'
  );
  runApp(MainApp());
}
 final supabase = Supabase.instance.client;
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: session != null ? HomeScreen() : Login(),
    );
  }
}