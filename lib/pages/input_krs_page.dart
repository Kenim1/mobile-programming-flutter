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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memuat data mahasiswa"),
          backgroundColor: Colors.red,
        ),
      );
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

      if (response.statusCode == 201 || response.statusCode == 202) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );

        semesterController.clear();
        _formKey.currentState!.reset();

        await _getDaftarKrs();
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

  // ==============================
  // GET DAFTAR KRS
  // ==============================
  Future<void> _getDaftarKrs() async {
    if (user == null) return;

    setState(() => isFetchingKrs = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.get(
        "${ApiService.baseUrl}krs/daftar-krs?id_mahasiswa=${user!['nim']}",
      );

      if (response.statusCode == 200) {
        setState(() {
          daftarKrs = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("ERROR GET KRS: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memuat daftar KRS"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isFetchingKrs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input KRS"),
        backgroundColor: Colors.blue,
      ),
      body: isFetching
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  // ==============================
  // UI CONTENT
  // ==============================
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // FORM INPUT
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: semesterController,
                  decoration: InputDecoration(
                    labelText: "Semester",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                        : const Icon(Icons.save),
                    label: Text(
                      isLoading ? "Menyimpan..." : "Simpan KRS",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // LIST KRS
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Daftar KRS Mahasiswa",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (isFetchingKrs)
            const Center(child: CircularProgressIndicator())
          else if (daftarKrs.isEmpty)
            const Text("Belum ada data KRS.")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daftarKrs.length,
              itemBuilder: (context, index) {
                final krs = daftarKrs[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Colors.blue),
                    title: const Text(
                      "KRS Anda",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Semester: ${krs['semester']} | Tahun: ${krs['tahun_ajaran']}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
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
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
