import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_service.dart';
import '../widgets/bottom_nav.dart';
import './detail_berita_pages.dart';

class DashboardPages extends StatefulWidget {
  const DashboardPages({super.key});

  @override
  State<DashboardPages> createState() => _DashboardPagesState();
}

class _DashboardPagesState extends State<DashboardPages> {
  Map<String, dynamic>? user;
  List<dynamic> beritaAkademik = [];

  final List<Map<String, dynamic>> menuItems = [
    {"icon": Icons.school, "label": "KRS"},
    {"icon": Icons.grade, "label": "KHS"},
    {"icon": Icons.calendar_month, "label": "Jadwal"},
    {"icon": Icons.person, "label": "Profil"},
    {"icon": Icons.bar_chart, "label": "IPK"},
    {"icon": Icons.help, "label": "Bantuan"},
    {"icon": Icons.settings, "label": "Pengaturan"},
  ];

  @override
  void initState() {
    super.initState();
    _getMahasiswaData();
    _getBeritaAkademik();
  }

  // ===== GET DATA MAHASISWA =====
  Future<void> _getMahasiswaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final email = prefs.getString("auth_email");

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';

      final response = await dio.post(
        "${ApiService.baseUrl}mahasiswa/detail-mahasiswa",
        data: {"email": email},
      );
      setState(() {
        user = response.data["data"];
      });
    } catch (e) {
      debugPrint("Error getMahasiswa: $e");
    }
  }

  // ===== GET BERITA AKADEMIK =====
  Future<void> _getBeritaAkademik() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';

      final response = await dio.get("${ApiService.baseUrl}info/berita");
      setState(() {
        beritaAkademik = response.data["data"] ?? [];
      });
    } catch (e) {
      debugPrint("Error getBerita: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFoto =
        (user?["foto"] != null &&
        (user?["foto"]?.toString().isNotEmpty ?? false));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Mahasiswa"),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ===== PROFILE CARD =====
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: hasFoto
                              ? NetworkImage(user!["foto"])
                              : const AssetImage(
                                      "assets/images/default_user.png",
                                    )
                                    as ImageProvider,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?["nama"] ?? "-",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(user?["email"] ?? "-"),
                              Text(user?["nim"] ?? "-"),
                              Text(
                                "${user?["program_studi"]?["nama_prodi"] ?? '-'} - ${user?["angkatan"] ?? '-'}",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ===== MENU GRID =====
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: menuItems
                        .map(
                          (item) => Column(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(
                                  item["icon"],
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item["label"],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 25),

                  // ===== BERITA AKADEMIK (CARD LIST) =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Berita Akademik",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  beritaAkademik.isEmpty
                      ? const Text("Belum Ada berita Akademik")
                      : ListView.builder(
                          itemCount: beritaAkademik.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final berita = beritaAkademik[index];
                            final judul = berita["judul"] ?? "Tanpa Judul";
                            final slug = berita["slug"] ?? "";
                            final tanggal = berita["createdAt"] ?? "";

                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.article_rounded,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  judul,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(
                                      slug,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Tanggal: $tanggal",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailBeritaPages(berita: berita),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}
