import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_service.dart';

class ProfilePages extends StatefulWidget {
  const ProfilePages({super.key});

  @override
  State<ProfilePages> createState() => _ProfilePagesState();
}

class _ProfilePagesState extends State<ProfilePages> {
  Map<String, dynamic>? user;
  bool isLoading = false;
  final formKey = GlobalKey<FormState>();

  // Controller biodata
  final namaC = TextEditingController();
  final jkC = TextEditingController();
  final tglC = TextEditingController();
  final alamatC = TextEditingController();
  final statusC = TextEditingController();

  // Gambar (support Web & Mobile)
  Uint8List? webImage;
  XFile? pickedFile;

  @override
  void initState() {
    super.initState();
    _getMahasiswaData();
  }

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
      namaC.text = user?['nama'] ?? '';
      jkC.text = user?['jenis_kelamin'] ?? '';
      tglC.text = user?['tanggal_lahir'] ?? '';
      alamatC.text = user?['alamat'] ?? '';
      statusC.text = user?['status'] ?? '';
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        // Web pakai bytes
        final bytes = await image.readAsBytes();
        setState(() {
          webImage = bytes;
          pickedFile = image;
        });
        _uploadFotoWeb(bytes, image.name);
      } else {
        // Mobile pakai path
        setState(() {
          pickedFile = image;
        });
        _uploadFotoMobile(image);
      }
    }
  }

  Future<void> _uploadFotoMobile(XFile image) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final nim = user?['nim'];

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final formData = FormData.fromMap({
        'nim': nim,
        'foto': await MultipartFile.fromFile(image.path),
      });

      final response = await dio.post(
        "${ApiService.baseUrl}mahasiswa/upload-foto-mahasiswa",
        data: formData,
      );

      if (response.data['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profil berhasil diperbarui!")),
        );
        _getMahasiswaData();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal upload foto: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadFotoWeb(Uint8List bytes, String filename) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final nim = user?['nim'];

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final formData = FormData.fromMap({
        'nim': nim,
        'foto': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await dio.post(
        "${ApiService.baseUrl}mahasiswa/upload-foto-mahasiswa",
        data: formData,
      );

      if (response.data['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profil berhasil diperbarui!")),
        );
        _getMahasiswaData();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal upload foto: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateBiodata() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final nim = user?['nim'];

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.put(
        "${ApiService.baseUrl}mahasiswa/update-mahasiswa",
        data: {
          "nim": nim,
          "nama": namaC.text,
          "jenis_kelamin": jkC.text,
          "tanggal_lahir": tglC.text,
          "alamat": alamatC.text,
          "status": statusC.text,
        },
      );

      if (response.data['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Biodata berhasil diperbarui!")),
        );
        _getMahasiswaData();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal update biodata: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = user?["foto"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Mahasiswa"),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    // FOTO PROFIL
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: kIsWeb && webImage != null
                                ? MemoryImage(webImage!)
                                : pickedFile != null
                                ? Image.network(pickedFile!.path).image
                                : (fotoUrl != null && fotoUrl != "")
                                ? NetworkImage(fotoUrl)
                                : const AssetImage(
                                        "assets/images/default_user.png",
                                      )
                                      as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // BIODATA FORM
                    TextFormField(
                      controller: namaC,
                      decoration: const InputDecoration(labelText: "Nama"),
                      validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: jkC,
                      decoration: const InputDecoration(
                        labelText: "Jenis Kelamin",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: tglC,
                      decoration: const InputDecoration(
                        labelText: "Tanggal Lahir (YYYY-MM-DD)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: alamatC,
                      decoration: const InputDecoration(labelText: "Alamat"),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: statusC,
                      decoration: const InputDecoration(labelText: "Status"),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _updateBiodata,
                      icon: const Icon(Icons.save),
                      label: Text(
                        isLoading ? "Menyimpan..." : "Simpan Perubahan",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
