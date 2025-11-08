import 'package:flutter/material.dart';
import 'package:siakad/api/api_service.dart';
import 'package:siakad/pages/login_pages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIAKAD',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(color: Colors.white, child: child),
          ),
        );
      },

      home: FutureBuilder(
        future: ApiService.getSession(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoginPages();
          } else {
            return const LoginPages(); // nanti bisa diganti Dashboard
          }
        },
      ),
    );
  }
}
