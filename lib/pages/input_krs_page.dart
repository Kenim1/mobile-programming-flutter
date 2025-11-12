import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class InputKrsPage extends StatefulWidget {
  const InputKrsPage({super.key});

  @override
  State<InputKrsPage> createState() => _InputKrsPageState();
}

class _InputKrsPageState extends State<InputKrsPage> {
  Map<String, dynamic>? user;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController semesterController = TextEditingController();

  bool isLoading = false;
  bool isFetchingKrs = false;
  List<dynamic> daftarKrs = [];

  @override
  void initState() {
    super.initState();
    _getMahasiswaData();
  }

  // ===== GET DATA MAHASISWA DARI TOKEN =====
  Future<void> _getMahasiswaData() async {
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
  }

  // ====== INPUT KRS ======
  Future<void> _submitKrs() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';

    final String url = '${ApiService.baseUrl}krs/buat-krs';

    try {
      final response = await dio.post(
        url,
        data: {'nim': user?['nim'], 'semester': semesterController.text},
        options: Options(headers: {"Accept": "application/json"}),
      );

      if (response.statusCode == 200) {
        final status = response.data['status'];
        final msg = response.data['msg'] ?? "KRS berhasil disimpan";

        if (status == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green),
          );
          _formKey.currentState!.reset();
          semesterController.clear();
          await _getDaftarKrs(); // tampilkan daftar KRS setelah berhasil simpan
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.orange),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mengirim data ke server"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.response?.data['message'] ?? e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ===== GET DAFTAR KRS BERDASARKAN NIM =====
  Future<void> _getDaftarKrs() async {
    setState(() {
      isFetchingKrs = true;
      daftarKrs = [];
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';

    final String url =
        '${ApiService.baseUrl}krs/daftar-krs?id_mahasiswa=${user?['nim']}';

    try {
      final response = await dio.get(url);

      if (response.statusCode == 200 && response.data['status'] == 200) {
        setState(() {
          daftarKrs = response.data['data'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['msg'] ?? 'Gagal memuat daftar KRS'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error get daftar KRS: $e');
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
        backgroundColor: Colors.deepPurple,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ===== FORM INPUT KRS =====
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
                              backgroundColor: Colors.deepPurple,
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

                  // ===== DAFTAR KRS =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Daftar KRS Mahasiswa",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (isFetchingKrs)
                    const Center(child: CircularProgressIndicator())
                  else if (daftarKrs.isEmpty)
                    const Text("Belum ada data KRS yang tersimpan.")
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: daftarKrs.length,
                      itemBuilder: (context, index) {
                        final krs = daftarKrs[index];
                        final semester = krs['semester']?.toString() ?? '-';
                        final tahun = krs['tahun_ajaran'] ?? '-';

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.book,
                              color: Colors.deepPurple,
                            ),
                            title: Text(
                              "KRS Anda",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Semester: $semester | Tahun: $tahun",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
