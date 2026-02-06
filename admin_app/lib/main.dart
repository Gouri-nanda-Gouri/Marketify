import 'package:admin_app/dashboard.dart';
import 'package:admin_app/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  await Supabase.initialize(
    url: 'https://wrfaepzyswceofnkmlik.supabase.co',
    anonKey: 'sb_publishable_wX8bBde5lL1iSS3Tp9zpEg_T5J6xdCR',
  );
  runApp(MainApp());
}
 final supabase = Supabase.instance.client;


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      home: AdminDashboard(),
    );
  }
}
