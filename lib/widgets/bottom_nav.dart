import 'package:flutter/material.dart';
import '../pages/profile_pages.dart';
import '../pages/dashboard_pages.dart';
// Asumsikan Anda punya halaman lain
// import '../pages/search_pages.dart'; 
// import '../pages/favorite_pages.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // Warna konsisten
  const Color primaryColor = Color(0xFF003366); // Navy Blue
  const Color accentColor = Color(0xFFF7931E);  // Orange

  int _currentIndex = 0;

  // DAFTAR HALAMAN (Hanya ganti di sini jika ada penambahan/pengurangan tab)
  final List<Widget> _pages = [
    const DashboardPages(),
    const Center(child: Text("Halaman Pencarian (Coming Soon)")), // Ganti dengan SearchPage()
    const Center(child: Text("Halaman Favorit (Coming Soon)")), // Ganti dengan FavoritePage()
    const ProfilePages(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body menampung semua halaman tanpa me-render ulang (IndexedStack)
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          
          // Warna dan Tema Bottom Nav Bar
          backgroundColor: primaryColor,
          selectedItemColor: accentColor, // Warna aktif: Orange
          unselectedItemColor: Colors.white70, // Warna non-aktif: Putih pudar
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: accentColor),
          unselectedLabelStyle: const TextStyle(fontSize: 10, color: Colors.white70),
          
          currentIndex: _currentIndex,
          onTap: _onItemTapped, // Menggunakan fungsi setState sederhana

          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard, size: 24),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 24),
              label: "Pencarian",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite, size: 24),
              label: "Favorite",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 24),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}