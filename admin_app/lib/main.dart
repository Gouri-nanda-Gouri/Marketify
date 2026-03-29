import 'package:admin_app/dashboard.dart';
import 'package:admin_app/login.dart';
import 'package:admin_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  await Supabase.initialize(
      url: 'https://jhaqkfxtixmoxhvipult.supabase.co',
    anonKey: 'sb_publishable_CFHSwkELXkpWb7mKQSiVlg_h5ZsSyU0'
  );
  runApp(const MainApp());
}
 final supabase = Supabase.instance.client;


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: AdminDashboard(),
    );
  }
}
