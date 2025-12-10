import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:siakad/pages/dashboard_pages.dart';
import 'package:siakad/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: avoid_web_libraries_in_flutter
import './webcam_helper.dart';

void main() {
  // Hanya jalankan registerViewFactory jika running di Web
  if (html.Platform.operatingSystem == 'web') {
    // Registrasi WebView untuk Maps (jika digunakan)
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
        'maps-view', (int viewId) => html.IFrameElement()
          ..id = 'map-frame'
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..src = 'assets/maps_detail_absensi.html');
          
    // Registrasi WebView untuk Webcam (sudah ada di kode Anda)
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
        'webcam-view',
        (int viewId) => html.DivElement()
          ..id = 'webcam-container'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'black');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisikan warna branding kampus
    const Color primaryColor = Color(0xFF003366); // Navy/Biru Kampus

    return MaterialApp(
      title: 'SIAKAD',
      theme: ThemeData(
        // 1. Tentukan warna dasar/branding kampus
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: const Color(0xFFF7931E), // Aksen Orange
        ),
        // 2. Terapkan Desain Material 3
        useMaterial3: true,
        // 3. Terapkan tema AppBar global
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      // Set ConstrainedBox untuk tampilan mobile di Web
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(color: Colors.white, child: child),
          ),
        );
      },
      home: FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final prefs = snapshot.data;
          final token = prefs?.getString('auth_token');

          if (token != null) {
            return const DashboardPages();
          } else {
            return const LoginPages();
          }
        },
      ),
    );
  }
}