import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './absen_submit_page.dart';
import './detail_absensi_page.dart';
import '../api/api_service.dart';

class AbsenPage extends StatefulWidget {
  final int idKrsDetail;
  final String namaMatkul;

  const AbsenPage({
    super.key,
    required this.idKrsDetail,
    required this.namaMatkul,
  });

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  List<bool> sudahAbsen = List.generate(16, (_) => false);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStatusAbsen();
  }

  Future<void> loadStatusAbsen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      Dio dio = Dio();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      // cek status pertemuan 1–16
      for (int i = 1; i <= 16; i++) {
        final url =
            "${ApiService.baseUrl}absensi/detail?id_krs_detail=${widget.idKrsDetail}&pertemuan=$i";

        try {
          final res = await dio.get(url);
          if (res.data["data"] != null) {
            sudahAbsen[i - 1] = true;
          }
        } catch (e) {
          // bisa diabaikan per pertemuan, atau log kalau perlu
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat status absensi")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Absen - ${widget.namaMatkul}"),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 16,
              itemBuilder: (context, index) {
                final pertemuan = index + 1;
                final isDone = sudahAbsen[index];

                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: isDone ? Colors.green : Colors.grey,
                    ),
                    title: Text("Pertemuan $pertemuan"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDone)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailAbsensiPage(
                                    idKrsDetail: widget.idKrsDetail,
                                    pertemuan: pertemuan,
                                    namaMatkul: widget.namaMatkul,
                                  ),
                                ),
                              );
                            },
                            child: const Text("Lihat"),
                          ),
                        if (isDone) const SizedBox(width: 8),
                        if (!isDone)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AbsenSubmitPage(
                                    idKrsDetail: widget.idKrsDetail,
                                    pertemuan: pertemuan,
                                    namaMatkul: widget.namaMatkul,
                                  ),
                                ),
                              );
                            },
                            child: const Text("Absen"),
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
