import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class EditProfil extends StatefulWidget {
  const EditProfil({super.key});

  @override
  State<EditProfil> createState() => _EditProfilState();
}

class _EditProfilState extends State<EditProfil> {
  static const _primary = Color(0xFF1565C0);

  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _nik = '-';
  String? _profilePhoto;
  XFile? _profilePhotoXFile;
  File? _profilePhotoFile;
  bool _isLoading = false;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _noHpCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await ApiService.getUserData();
    if (mounted) {
      setState(() {
        _namaCtrl.text = data['name'] ?? '';
        _noHpCtrl.text = data['no_hp'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
        _nik = data['nik'] ?? '-';
        _profilePhoto = data['profile_photo'];
        _loadingData = false;
      });
    }
  }

  Future<void> _pilihFotoProfil() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _profilePhotoXFile = picked;
      if (!kIsWeb) {
        _profilePhotoFile = File(picked.path);
      }
    });
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final resp = await ApiService.updateProfile({
        'name': _namaCtrl.text.trim(),
        'no_hp': _noHpCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty)
          'email': _emailCtrl.text.trim(),
      });
      if (!mounted) return;

      Map<String, dynamic>? body;
      if (resp.body.isNotEmpty) {
        try {
          body = jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {
          body = null;
        }
      }

      if (resp.statusCode == 200) {
        Map<String, dynamic>? updatedUser;
        if (body?['user'] != null) {
          updatedUser = (body!['user'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v?.toString() ?? ''));
        }

        if (_profilePhotoXFile != null) {
          final photoResp = await ApiService.updateProfilePhoto(
            kIsWeb ? _profilePhotoXFile : _profilePhotoFile,
          );
          if (!mounted) return;
          if (photoResp.statusCode == 200) {
            Map<String, dynamic>? photoBody;
            if (photoResp.body.isNotEmpty) {
              try {
                photoBody = jsonDecode(photoResp.body) as Map<String, dynamic>;
              } catch (_) {}
            }
            if (photoBody?['user'] != null) {
              updatedUser = (photoBody!['user'] as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, v?.toString() ?? ''));
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ApiService.errorMessage(photoResp,
                    fallback: 'Profil tersimpan, tapi foto gagal diupload')),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        if (updatedUser != null) {
          await ApiService.saveUserData(updatedUser);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body?['message'] ?? 'Gagal memperbarui profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: _primary.withOpacity(0.1),
                          child: ClipOval(child: _buildProfilePreview()),
                        ),
                        Material(
                          color: _primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pilihFotoProfil,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.camera_alt,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pilihFotoProfil,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(_profilePhotoXFile == null
                          ? 'Pilih Foto Profil'
                          : 'Ganti Foto Profil'),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi Pribadi',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _primary)),
                          const Divider(height: 16),
                          // Nama
                          TextFormField(
                            controller: _namaCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap *',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => v!.trim().isEmpty
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // NIK (readonly)
                          TextFormField(
                            initialValue: _nik,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'NIK (tidak dapat diubah)',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // No HP
                          TextFormField(
                            controller: _noHpCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Nomor HP *',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => v!.trim().isEmpty
                                ? 'No. HP wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email (opsional)',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _simpan,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: const Text('SIMPAN PERUBAHAN',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePreview() {
    if (_profilePhotoXFile != null) {
      if (kIsWeb) {
        return Image.network(
          _profilePhotoXFile!.path,
          width: 104,
          height: 104,
          fit: BoxFit.cover,
        );
      }
      return Image.file(
        _profilePhotoFile!,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
      );
    }

    if (_profilePhoto != null && _profilePhoto!.isNotEmpty) {
      return Image.network(
        ApiService.buildStorageUrl(_profilePhoto!),
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded,
            size: 56, color: _primary),
      );
    }

    return const Icon(Icons.person_rounded, size: 56, color: _primary);
  }
}
