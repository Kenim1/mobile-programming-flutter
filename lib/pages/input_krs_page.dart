import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import './krs_detail_page.dart';

class InputKrsPage extends StatefulWidget {
  const InputKrsPage({super.key});

  @override
  State<InputKrsPage> createState() => _InputKrsPageState();
}

class _InputKrsPageState extends State<InputKrsPage> {
  Map<String, dynamic>? user;

  // Warna konsisten
  final Color primaryColor = const Color(0xFF003366); 
  final Color accentColor = const Color(0xFFF7931E);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController semesterController = TextEditingController();

  bool isLoading = false; // untuk submit
  bool isFetching = true; // untuk seluruh data awal
  bool isFetchingKrs = false;

  List<dynamic> daftarKrs = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // ==============================
  // METODE BUILD YANG HILANG (Kini ada!)
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Rencana Studi (KRS)'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isFetching
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _buildContent(), // Memanggil konten UI
    );
  }

  // ==============================
  // UI CONTENT
  // ==============================
  Widget _buildContent() {
    // Pastikan user data sudah dimuat sebelum menampilkan konten
    if (user == null) {
      return const Center(
        child: Text(
          "Gagal memuat data mahasiswa. Coba muat ulang.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Tampilkan Info Mahasiswa di atas
          _buildUserInfo(),
          const SizedBox(height: 30),

          // FORM INPUT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Buat KRS Baru",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: semesterController,
                    decoration: _inputDecoration("Semester yang Diambil (Contoh: 3)", Icons.format_list_numbered),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty
                        ? "Semester wajib diisi"
                        : null,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _submitKrs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add_to_photos),
                      label: Text(
                        isLoading ? "Menyimpan..." : "BUAT KRS",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // LIST KRS
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Daftar Riwayat KRS",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 15),

          if (isFetchingKrs)
            Center(child: CircularProgressIndicator(color: primaryColor))
          else if (daftarKrs.isEmpty)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text("Belum ada data KRS yang tersimpan.", style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daftarKrs.length,
              itemBuilder: (context, index) {
                final krs = daftarKrs[index];
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: CircleAvatar(
                      backgroundColor: accentColor,
                      child: Text(
                        krs['semester']?.toString() ?? '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      "KRS Semester ${krs['semester']}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    subtitle: Text(
                      "Tahun Ajaran: ${krs['tahun_ajaran'] ?? '-'}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Icon(Icons.chevron_right, color: primaryColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KrsDetailPage(
                            idKrs: krs['id'],
                            semester: krs['semester']?.toString() ?? "-",
                            tahunAjaran: krs['tahun_ajaran']?.toString() ?? "-",
                          ),
                        ),
                      ).then((_) {
                        // Refresh data setelah kembali dari Detail Page
                        _getDaftarKrs(); 
                      });
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- HELPER UNTUK TAMPILAN INFO MAHASISWA ---
  Widget _buildUserInfo() {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.person, color: accentColor, size: 40),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user!['nama'] ?? 'Nama Mahasiswa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('NIM: ${user!['nim']}', style: TextStyle(fontSize: 14)),
                  Text('Prodi: ${user!['prodi'] ?? '-'}', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER UNTUK TEXT FIELD DESIGN ---
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    );
  }

  // ==============================
  // LOAD DATA USER + DAFTAR KRS
  // ==============================
  Future<void> _loadInitialData() async {
    await _getMahasiswaData();
    if (user != null) {
      await _getDaftarKrs();
    }

    setState(() {
      isFetching = false;
    });
  }

  // ==============================
  // GET DATA MAHASISWA DARI TOKEN
  // ==============================
  Future<void> _getMahasiswaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final email = prefs.getString('auth_email');

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.post(
        "${ApiService.baseUrl}mahasiswa/detail-mahasiswa",
        data: {"email": email},
      );

      setState(() {
        user = response.data['data'];
      });
    } catch (e) {
      debugPrint("ERROR GET USER: $e");
      // Tidak menampilkan Snackbar di sini agar tidak menumpuk saat startup
    }
  }

  // ==============================
  // SUBMIT KRS
  // ==============================
  Future<void> _submitKrs() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.post(
        "${ApiService.baseUrl}krs/buat-krs",
        data: {'nim': user?['nim'], 'semester': semesterController.text},
      );

      final msg = response.data['message'] ?? "KRS berhasil disimpan";

      if (response.statusCode == 201 || response.statusCode == 202 || response.data['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );

        semesterController.clear();
        _formKey.currentState!.reset();

        await _getDaftarKrs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['msg'] ?? "Gagal menyimpan data"), backgroundColor: Colors.red),
        );
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.response?.data['message'] ?? "Gagal menyimpan data"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ====================================================
  // GET DAFTAR KRS
  // ====================================================
  Future<void> _getDaftarKrs() async {
    if (user == null) {
      debugPrint("User data is null. Cannot fetch KRS.");
      setState(() => isFetchingKrs = false);
      return;
    }

    setState(() => isFetchingKrs = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.get(
        "${ApiService.baseUrl}krs/daftar-krs",
        queryParameters: {
          'nim': user!['nim'], // Menggunakan NIM sebagai parameter
        },
      );

      // Cek status code dan status di body
      if (response.statusCode == 200 && response.data['status'] == 200) {
        setState(() {
          // Asumsi data KRS berada di kunci 'data'
          daftarKrs = response.data['data'] ?? [];
        });
        debugPrint("KRS Loaded: ${daftarKrs.length} items.");
      } else {
        setState(() {
          daftarKrs = [];
        });
        debugPrint("KRS Response Status Error: ${response.statusCode}");
      }
    } on DioException catch (e) {
      debugPrint("ERROR GET KRS: ${e.response?.data ?? e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat riwayat KRS: ${e.response?.data['message'] ?? 'Kesalahan Jaringan'}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint("An unknown error occurred: $e");
    } finally {
      setState(() => isFetchingKrs = false);
    }
  }
}