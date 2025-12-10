import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// import 'package:siakad/pages/detail_absensi_pages.dart'; // Pastikan path ini benar
// import '../api/api_service.dart';
// import 'absen_submit_page.dart';

// Asumsi: Anda memiliki file ini. Harap ganti dengan path yang benar.
class DetailAbsensiPage extends StatelessWidget {
  final int idKrsDetail;
  final int pertemuan;
  final String namaMatkul;

  const DetailAbsensiPage({
    super.key,
    required this.idKrsDetail,
    required this.pertemuan,
    required this.namaMatkul,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detail Absen Pertemuan $pertemuan")),
      body: Center(child: Text("Halaman Detail Absensi untuk $namaMatkul")),
    );
  }
}

// Asumsi: Anda memiliki file ini. Harap ganti dengan path yang benar.
class AbsenSubmitPage extends StatelessWidget {
  final int idKrsDetail;
  final int pertemuan;
  final String namaMatkul;

  const AbsenSubmitPage({
    super.key,
    required this.idKrsDetail,
    required this.pertemuan,
    required this.namaMatkul,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Submit Absensi Pertemuan $pertemuan")),
      body: Center(child: Text("Halaman Submit Absensi untuk $namaMatkul (Membutuhkan Geo-Fencing)")),
    );
  }
}

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
  // Warna konsisten
  const Color primaryColor = Color(0xFF003366);
  const Color accentColor = Color(0xFFF7931E);
  const Color successColor = Colors.green;

  // Struktur Data untuk menyimpan status absensi
  // Ganti data dummy ini dengan hasil fetch dari API
  bool isLoading = true; // Set true untuk load data awal
  List<bool> statusAbsenPertemuan = List.generate(16, (index) => false); 

  @override
  void initState() {
    super.initState();
    // Panggil fungsi API untuk mengambil status absensi di sini
    // loadStatusAbsen(); 
    
    // Karena tidak ada fungsi API, kita gunakan dummy data 
    // dan tunggu 1 detik untuk simulasi loading.
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        // Data dummy: Pertemuan 1, 4, 7, 10, 13, 16 sudah absen
        for(int i = 0; i < 16; i++) {
          if (i % 3 == 0) statusAbsenPertemuan[i] = true;
        }
        isLoading = false;
      });
    });
  }

  // Future<void> loadStatusAbsen() async {
  //   setState(() => isLoading = true);
  //   // === LOGIKA API GET STATUS ABSEN DARI ID_KRSDETAIL ===
  //   try {
  //     // ... API call menggunakan dio.get("${ApiService.baseUrl}absen/status-pertemuan?id_krs_detail=${widget.idKrsDetail}")
  //     // Misal API mengembalikan List<bool> atau List<Map<String, dynamic>>
  //     // setState(() {
  //     //   statusAbsenPertemuan = apiResponse.data['status']; // Sesuaikan dengan struktur API Anda
  //     //   isLoading = false;
  //     // });
  //   } catch (e) {
  //     // Handle error
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Absensi Mata Kuliah",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Matkul
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              widget.namaMatkul,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      final pertemuan = index + 1;
                      // Ambil status dari list yang telah dimuat
                      final isDone = index < statusAbsenPertemuan.length 
                                      ? statusAbsenPertemuan[index] 
                                      : false;

                      return _buildPertemuanCard(pertemuan, isDone, context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // CARD PERTEMUAN
  // ====================================================
  Widget _buildPertemuanCard(int pertemuan, bool isDone, BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // Border berwarna Hijau jika sudah absen
        side: isDone ? BorderSide(color: successColor.shade400, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pertemuan $pertemuan",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                // Status Absen (Badge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone ? successColor.shade100 : accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDone ? "SUDAH ABSEN" : "BELUM ABSEN",
                    style: TextStyle(
                      color: isDone ? successColor.shade800 : accentColor.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Tombol Aksi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone ? primaryColor : accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
                onPressed: () {
                  if (isDone) {
                    // Navigasi ke Lihat Absensi (DetailAbsensiPage)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailAbsensiPage(
                          idKrsDetail: widget.idKrsDetail,
                          pertemuan: pertemuan,
                          namaMatkul: widget.namaMatkul,
                        ),
                      ),
                    ).then((_) => setState(() {
                          // loadStatusAbsen(); // Refresh status setelah kembali dari detail
                        }));
                  } else {
                    // Navigasi ke Halaman Submit Absensi (AbsenSubmitPage)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AbsenSubmitPage(
                          idKrsDetail: widget.idKrsDetail,
                          pertemuan: pertemuan,
                          namaMatkul: widget.namaMatkul,
                        ),
                      ),
                    ).then((_) => setState(() {
                          // loadStatusAbsen(); // Refresh status setelah kembali dari submit
                        }));
                  }
                },
                icon: Icon(isDone ? Icons.visibility : Icons.qr_code_scanner),
                label: Text(
                  isDone ? "LIHAT DETAIL ABSENSI" : "LAKUKAN ABSENSI SEKARANG",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}