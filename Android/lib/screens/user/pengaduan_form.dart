import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../models/laporan_model.dart';
import 'package:http/http.dart' as http;

class PengaduanForm extends StatefulWidget {
  final LaporanModel? laporanToEdit;

  const PengaduanForm({super.key, this.laporanToEdit});

  @override
  State<PengaduanForm> createState() => _PengaduanFormState();
}

class _PengaduanFormState extends State<PengaduanForm> {
  static const _primary = Color(0xFF1565C0);

  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();

  List<Map<String, dynamic>> _kategoriList = [];
  int? _selectedKategoriId;
  String? _selectedKategoriNama;
  XFile? _fotoXFile;
  File? _foto;
  Position? _posisi;
  bool _isLoading = false;
  bool _loadingKategori = true;
  bool _loadingLokasi = false;

  @override
  void initState() {
    super.initState();
    _loadKategori();
    
    if (widget.laporanToEdit != null) {
      final l = widget.laporanToEdit!;
      _judulCtrl.text = l.judul;
      _deskripsiCtrl.text = l.deskripsi;
      if (l.latitude != null && l.longitude != null) {
        _posisi = Position(
          latitude: l.latitude!,
          longitude: l.longitude!,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    try {
      final data = await ApiService.getKategori();
      if (!mounted) return;
      setState(() {
        _kategoriList = data.cast<Map<String, dynamic>>();
        _loadingKategori = false;

        // Auto-select kategori if editing
        if (widget.laporanToEdit != null && widget.laporanToEdit!.kategori != null) {
          final matched = _kategoriList.firstWhere(
            (k) => k['nama_kategori'] == widget.laporanToEdit!.kategori,
            orElse: () => {},
          );
          if (matched.isNotEmpty) {
            _selectedKategoriId = matched['id'];
            _selectedKategoriNama = matched['nama_kategori'];
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingKategori = false);
    }
  }

  Future<void> _ambilLokasi() async {
    setState(() => _loadingLokasi = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snackbar('GPS tidak aktif. Aktifkan GPS terlebih dahulu.',
            isError: true);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _snackbar('Izin lokasi ditolak.', isError: true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _snackbar('Izin lokasi ditolak permanen. Ubah di Pengaturan.',
            isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() => _posisi = pos);
        _snackbar('Lokasi berhasil diambil');
      }
    } catch (e) {
      if (mounted) _snackbar('Gagal mengambil lokasi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingLokasi = false);
    }
  }

  Future<void> _pilihFoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null && mounted) {
      setState(() {
        _fotoXFile = picked;
        if (!kIsWeb) {
          _foto = File(picked.path);
        }
      });
    }
  }

  Future<void> _kirim() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategoriId == null) {
      _snackbar('Pilih kategori keluhan terlebih dahulu.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isEdit = widget.laporanToEdit != null;
      final http.Response resp;

      if (isEdit) {
        resp = await ApiService.updateLaporanUser(
          widget.laporanToEdit!.id,
          judul: _judulCtrl.text.trim(),
          kategoriId: _selectedKategoriId!,
          deskripsi: _deskripsiCtrl.text.trim(),
          latitude: _posisi?.latitude,
          longitude: _posisi?.longitude,
          fotoPengaduan: kIsWeb ? _fotoXFile : _foto,
        );
      } else {
        resp = await ApiService.createLaporan(
          judul: _judulCtrl.text.trim(),
          kategoriId: _selectedKategoriId!,
          deskripsi: _deskripsiCtrl.text.trim(),
          latitude: _posisi?.latitude,
          longitude: _posisi?.longitude,
          fotoPengaduan: kIsWeb ? _fotoXFile : _foto,
        );
      }

      if (!mounted) return;
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        _snackbar(isEdit ? 'Pengaduan berhasil diperbarui!' : 'Pengaduan berhasil dikirim!');
        Navigator.pop(context, true);
      } else {
        _snackbar(ApiService.errorMessage(resp,
            fallback: isEdit ? 'Gagal memperbarui pengaduan' : 'Gagal mengirim pengaduan'), isError: true);
      }
    } catch (e) {
      if (mounted) _snackbar('Koneksi error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.laporanToEdit != null ? 'Edit Pengaduan' : 'Buat Pengaduan'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _sectionCard('Informasi Pengaduan', [
                // Kategori
                const Text('Kategori Keluhan *',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54)),
                const SizedBox(height: 8),
                _loadingKategori
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: _selectedKategoriId == null
                                  ? Colors.grey.shade300
                                  : _primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedKategoriId,
                            hint: const Text(
                              'Pilih kategori...',
                              style: TextStyle(color: Colors.black45),
                            ),
                            isExpanded: true,
                            items: _kategoriList.map((k) {
                              return DropdownMenuItem<int>(
                                value: k['id'] as int,
                                child: Text(k['nama_kategori'] ?? '-'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              final k = _kategoriList
                                  .firstWhere((e) => e['id'] == val);
                              setState(() {
                                _selectedKategoriId = val;
                                _selectedKategoriNama =
                                    k['nama_kategori'];
                              });
                            },
                          ),
                        ),
                  ),
                  const SizedBox(height: 16),
                // Judul
                  TextFormField(
                  controller: _judulCtrl,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: 'Judul Pengaduan *',
                    hintText: 'Contoh: Jalan berlubang di Dusun 2',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                // Deskripsi
                  TextFormField(
                  controller: _deskripsiCtrl,
                    maxLines: 5,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Keluhan *',
                    hintText:
                        'Jelaskan masalah secara detail: lokasi, waktu kejadian, dampaknya...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                ),
              ]),
              const SizedBox(height: 12),
              _sectionCard('Lokasi Kejadian', [
                Row(
                  children: [
                    Expanded(
                      child: _posisi != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.green, size: 18),
                                    const SizedBox(width: 6),
                                    const Text('Lokasi diambil',
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_posisi!.latitude.toStringAsFixed(6)}, ${_posisi!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            )
                          : const Text(
                              'Belum ada lokasi',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                    ),
                    const SizedBox(width: 12),
                    _loadingLokasi
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : OutlinedButton.icon(
                            onPressed: _ambilLokasi,
                            icon: const Icon(Icons.my_location, size: 18),
                            label: Text(
                                _posisi != null ? 'Perbarui' : 'Ambil GPS'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _primary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                  ],
                ),
              ]),
              const SizedBox(height: 12),
              _sectionCard('Foto Pendukung', [
                if (_fotoXFile != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(
                            _fotoXFile!.path,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image, size: 50),
                              ),
                            ),
                          )
                        : Image.file(
                            _foto!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pilihFoto,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Ganti Foto'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                              _fotoXFile = null;
                              _foto = null;
                            }),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 18),
                        label: const Text('Hapus',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red)),
                      ),
                    ],
                  ),
                ] else ...[
                  InkWell(
                    onTap: _pilihFoto,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 120,
                    width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Ketuk untuk pilih foto',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _kirim,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isLoading 
                      ? 'Menyimpan...' 
                      : (widget.laporanToEdit != null ? 'SIMPAN PERUBAHAN' : 'KIRIM PENGADUAN'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
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
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _primary)),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }
}
