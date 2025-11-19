import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import './webcam_helper.dart';
import '../api/api_service.dart';

class AbsenSubmitPage extends StatefulWidget {
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
  State<AbsenSubmitPage> createState() => _AbsenSubmitPageState();
}

class _AbsenSubmitPageState extends State<AbsenSubmitPage> {
  final WebCamera cam = WebCamera();

  Uint8List? imageBytes;
  Position? position;

  bool isCameraReady = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    /// TIDAK BOLEH init kamera di sini (DOM belum ada)
    /// Jadi kita tunda setelah build selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCameraAfterRender();
    });
  }

  Future<void> _initializeCameraAfterRender() async {
    try {
      // Pastikan DOM webcam sudah muncul
      await Future.delayed(const Duration(milliseconds: 300));

      await cam.initialize();
      setState(() => isCameraReady = true);
    } catch (e) {
      debugPrint("Error init camera: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal akses kamera: $e")));
    }
  }

  @override
  void dispose() {
    cam.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final data = await cam.capture();
      setState(() => imageBytes = data);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal mengambil foto")));
    }
  }

  Future<void> _getLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lokasi tidak aktif")));
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Izin lokasi ditolak")));
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() => position = pos);
  }

  Future<void> _submitAbsen() async {
    if (imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Foto belum diambil")));
      return;
    }
    if (position == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lokasi belum diambil")));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      Dio dio = Dio();

      final form = FormData.fromMap({
        "id_krs_detail": widget.idKrsDetail,
        "pertemuan": widget.pertemuan,
        "latitude": position!.latitude,
        "longitude": position!.longitude,
        "foto": MultipartFile.fromBytes(
          imageBytes!,
          filename: "absen_${DateTime.now().millisecondsSinceEpoch}.png",
        ),
      });

      final res = await dio.post(
        "${ApiService.baseUrl}absensi/submit",
        data: form,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.data["message"] ?? "Absen berhasil")),
      );

      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal submit absen")));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Absen - ${widget.namaMatkul} (Pertemuan ${widget.pertemuan})",
        ),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Kamera:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),

            Container(
              height: 240,
              color: Colors.black,
              child: const HtmlElementView(viewType: 'webcam-view'),
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isCameraReady ? _capturePhoto : null,
              icon: const Icon(Icons.camera),
              label: const Text("Capture Foto"),
            ),

            if (imageBytes != null) ...[
              const SizedBox(height: 20),
              const Text("Hasil Foto:", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Image.memory(imageBytes!, height: 200),
            ],

            const Divider(height: 32),
            const Text("Lokasi:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              position == null
                  ? "Belum diambil"
                  : "Lat: ${position!.latitude}, Lng: ${position!.longitude}",
            ),
            ElevatedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.my_location),
              label: const Text("Ambil Lokasi"),
            ),

            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitAbsen,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Absen"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
