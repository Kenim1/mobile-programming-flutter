// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/api_service.dart';

class DetailAbsensiPage extends StatefulWidget {
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
  State<DetailAbsensiPage> createState() => _DetailAbsensiPageState();
}

class _DetailAbsensiPageState extends State<DetailAbsensiPage> {
  bool isLoading = true;
  Map<String, dynamic>? data;
  String? mapViewType;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      Dio dio = Dio();

      final url =
          "${ApiService.baseUrl}absensi/detail?id_krs_detail=${widget.idKrsDetail}&pertemuan=${widget.pertemuan}";

      final res = await dio.get(url);

      data = res.data["data"];

      if (data != null) {
        final lat = data!['latitude'];
        final lng = data!['longitude'];

        // unique id setiap map
        mapViewType = "maps-view-${DateTime.now().millisecondsSinceEpoch}";

        // register iframe MAP langsung DI SINI
        ui_web.platformViewRegistry.registerViewFactory(mapViewType!, (
          int viewId,
        ) {
          final iframe = html.IFrameElement()
            ..src = "https://www.google.com/maps?q=$lat,$lng&z=16&output=embed"
            ..style.border = "0"
            ..style.width = "100%"
            ..style.height = "100%";

          return iframe;
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal mengambil data")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detail Absensi - ${widget.namaMatkul} (P.${widget.pertemuan})",
        ),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(
              child: Text("Belum ada absensi", style: TextStyle(fontSize: 16)),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    "${data!['foto']}",
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  const SizedBox(height: 16),
                  Text("Pertemuan : ${data!['pertemuan']}"),
                  Text("Latitude   : ${data!['latitude']}"),
                  Text("Longitude  : ${data!['longitude']}"),
                  Text("Waktu      : ${data!['created_at'] ?? '-'}"),

                  const SizedBox(height: 20),
                  const Text(
                    "Lokasi pada Peta:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (mapViewType != null)
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: HtmlElementView(viewType: mapViewType!),
                    ),
                ],
              ),
            ),
    );
  }
}
