import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';
import './absen_page.dart';

class KrsDetailPage extends StatefulWidget {
  final int idKrs;
  final String semester;
  final String tahunAjaran;

  const KrsDetailPage({
    super.key,
    required this.idKrs,
    required this.semester,
    required this.tahunAjaran,
  });

  @override
  State<KrsDetailPage> createState() => _KrsDetailPageState();
}

class _KrsDetailPageState extends State<KrsDetailPage> {
  List<dynamic> daftarMatkul = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getDetailKrs();
  }

  // ====================================================
  // BUKA LINK ZOOM
  // ====================================================
  Future<void> _openZoom(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Link Zoom tidak tersedia"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal membuka Zoom"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ====================================================
  // HAPUS MATAKULIAH DARI KRS
  // ====================================================
  Future<void> _hapusMatakuliah(int idKrsDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await dio.delete(
        "${ApiService.baseUrl}krs/hapus-course-krs?id=${idKrsDetail}",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.data['message'] ?? "Matakuliah dihapus"),
          backgroundColor: Colors.green,
        ),
      );

      _getDetailKrs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menghapus matakuliah"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ====================================================
  // GET DETAIL KRS (LIST MATKUL)
  // ====================================================
  Future<void> _getDetailKrs() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';

    final url = "${ApiService.baseUrl}krs/detail-krs?id_krs=${widget.idKrs}";

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        setState(() {
          daftarMatkul = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error get KRS: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memuat detail KRS"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ====================================================
  // TAMBAH MATAKULIAH (BOTTOM SHEET)
  // ====================================================
  void _tambahMatkulModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return TambahMatkulSheet(
          idKrs: widget.idKrs,
          onSuccess: () => _getDetailKrs(),
        );
      },
    );
  }

  // ====================================================
  // UI UTAMA
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detail KRS Semester ${widget.semester}"),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahMatkulModal,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : daftarMatkul.isEmpty
          ? const Center(
              child: Text(
                "Belum ada matakuliah\nyang dipilih.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: daftarMatkul.length,
              itemBuilder: (context, index) {
                final mk = daftarMatkul[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.blue,
                    ),
                    title: Text(mk['nama_matakuliah'] ?? '-'),
                    subtitle: Text(
                      "SKS: ${mk['jumlah_sks']?.toString() ?? '-'} | Dosen: ${mk['dosen'] ?? '-'}\n"
                      "Jadwal: ${mk['nama_hari'] ?? '-'}, "
                      "${mk['jam_mulai'] ?? '-'} - ${mk['jam_selesai'] ?? '-'}",
                    ),

                    // ====================================================
                    // BUTTON ZOOM + ABSEN + HAPUS
                    // ====================================================
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // BUTTON ZOOM
                        IconButton(
                          icon: const Icon(
                            Icons.video_camera_front,
                            color: Colors.blue,
                          ),
                          tooltip: "Buka Zoom",
                          onPressed: () =>
                              _openZoom(mk['zoom_link']), // <== NEW !!
                        ),

                        // BUTTON ABSEN
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          tooltip: "Masuk Absen",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AbsenPage(
                                  idKrsDetail: mk['id'],
                                  namaMatkul: mk['nama_matakuliah'],
                                ),
                              ),
                            );
                          },
                        ),

                        // BUTTON HAPUS
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Hapus Matakuliah",
                          onPressed: () => _hapusMatakuliah(mk['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ====================================================================
// SHEET TAMBAH MATKUL
// ====================================================================

class TambahMatkulSheet extends StatefulWidget {
  final int idKrs;
  final VoidCallback onSuccess;

  const TambahMatkulSheet({
    super.key,
    required this.idKrs,
    required this.onSuccess,
  });

  @override
  State<TambahMatkulSheet> createState() => _TambahMatkulSheetState();
}

class _TambahMatkulSheetState extends State<TambahMatkulSheet> {
  List<dynamic> daftarMatkulTersedia = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMatkul();
  }

  Future<void> loadMatkul() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final res = await dio.get("${ApiService.baseUrl}jadwal/daftar-jadwal");

      setState(() {
        daftarMatkulTersedia = res.data['jadwals'] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal memuat matakuliah")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> tambahMatkul(int idJadwal) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final res = await dio.post(
        "${ApiService.baseUrl}krs/tambah-course-krs",
        data: {"id_krs": widget.idKrs, "id_jadwal": idJadwal},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message']),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menambahkan matakuliah"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: daftarMatkulTersedia.length,
              itemBuilder: (context, index) {
                final mk = daftarMatkulTersedia[index];

                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(mk['nama_matakuliah']),
                    subtitle: Text(
                      "SKS: ${mk['jumlah_sks']} | ${mk['nama_hari']}, "
                      "${mk['jam_mulai']} - ${mk['jam_selesai']}",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => tambahMatkul(mk['id']),
                      child: const Text("Tambah"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
