import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'detail_absensi_page.dart'; 
import '../api/api_service.dart';
import 'absen_submit_page.dart'; 
import '../widgets/bottom_nav.dart'; 

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
  // FIX 2: Ubah final Color menjadi final Color
  final Color primaryColor = const Color(0xFF003366);
  final Color accentColor = const Color(0xFFF7931E);
  
  // FIX 3: Gunakan MaterialColor atau tentukan warna untuk shade
  final MaterialColor successColor = Colors.green; 

  bool isLoading = true; 
  List<bool> statusAbsenPertemuan = List.generate(16, (index) => false); 

  @override
  void initState() {
    super.initState();
    // loadStatusAbsen(); 
    
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        for(int i = 0; i < 16; i++) {
          if (i % 3 == 0) statusAbsenPertemuan[i] = true;
        }
        isLoading = false;
      });
    });
  }

  // ... (Fungsi loadStatusAbsen() Anda tetap sama)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Absensi Mata Kuliah",
          // FIX: Hapus const
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        // Color sudah diatur di main.dart AppBarTheme, tapi jika ingin override:
        // backgroundColor: primaryColor, 
        // iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              // FIX: Hapus const
              color: primaryColor.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              widget.namaMatkul,
              // FIX: Hapus const
              style: TextStyle( 
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          
          Expanded(
            child: isLoading
                // FIX: Hapus const
                ? Center(child: CircularProgressIndicator(color: primaryColor)) 
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      final pertemuan = index + 1;
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

  Widget _buildPertemuanCard(int pertemuan, bool isDone, BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
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
                  // FIX: Hapus const
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone ? successColor.shade100 : accentColor.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDone ? "SUDAH ABSEN" : "BELUM ABSEN",
                    style: TextStyle(
                      // FIX: Sekarang successColor dan accentColor adalah MaterialColor/Color.
                      // Jika accentColor dideklarasikan di main.dart (Color), .shade800 tidak akan bekerja.
                      // Saya asumsikan accentColor Anda di MainWrapper adalah Color, jadi kita pakai warna utama saja.
                      color: isDone ? successColor.shade800 : accentColor, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // FIX: Hapus const
                style: ElevatedButton.styleFrom( 
                  backgroundColor: isDone ? primaryColor : accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
                onPressed: () {
                  if (isDone) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // FIX 4: Gunakan DetailAbsensiPages (pastikan nama widget ini benar di file Anda)
                        builder: (_) => DetailAbsensiPage(
                          idKrsDetail: widget.idKrsDetail,
                          pertemuan: pertemuan,
                          namaMatkul: widget.namaMatkul,
                        ),
                      ),
                    ).then((_) => setState(() {})); 
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AbsenSubmitPage(
                          idKrsDetail: widget.idKrsDetail,
                          pertemuan: pertemuan,
                          namaMatkul: widget.namaMatkul,
                        ),
                      ),
                    ).then((_) => setState(() {})); 
                  }
                },
                // FIX: Hapus const
                icon: Icon(isDone ? Icons.visibility : Icons.qr_code_scanner), 
                label: Text(
                  // FIX 5: Teks ini tidak bisa constant karena isDone adalah variabel
                  isDone ? "LIHAT DETAIL ABSENSI" : "LAKUKAN ABSENSI SEKARANG", 
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}