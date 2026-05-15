import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/laporan_model.dart';
import '../../services/api_service.dart';
import 'chat_laporan_admin_screen.dart';

class LaporanDetailScreen extends StatefulWidget {
  final LaporanModel laporan;
  const LaporanDetailScreen({super.key, required this.laporan});

  @override
  State<LaporanDetailScreen> createState() => _LaporanDetailScreenState();
}

class _LaporanDetailScreenState extends State<LaporanDetailScreen> {
  static const _primary = Color(0xFF0D47A1);
  late String _selectedStatus;
  late final TextEditingController _tanggapanCtrl;
  XFile? _fotoProsesXFile;
  File? _fotoProses;
  XFile? _fotoBuktiXFile;
  File? _fotoBukti;
  bool _isLoading = false;

  final _statusList = ['Belum Ditangani', 'Sedang Diproses', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.laporan.status;
    _tanggapanCtrl =
        TextEditingController(text: widget.laporan.tanggapan ?? '');
  }

  @override
  void dispose() {
    _tanggapanCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Selesai':
        return const Color(0xFF43A047);
      case 'Sedang Diproses':
        return const Color(0xFFFF8F00);
      default:
        return const Color(0xFFE53935);
    }
  }

  Future<void> _pickImage({required bool isProcess}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isProcess) {
          _fotoProsesXFile = picked;
          if (!kIsWeb) {
            _fotoProses = File(picked.path);
          }
        } else {
          _fotoBuktiXFile = picked;
          if (!kIsWeb) {
            _fotoBukti = File(picked.path);
          }
        }
      });
    }
  }

  Future<void> _openMaps(double latitude, double longitude) async {
    final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      final opened =
          await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      if (!opened) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _simpan() async {
    if (_selectedStatus == 'Sedang Diproses' &&
        _fotoProsesXFile == null &&
        widget.laporan.fotoProses == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Foto bukti proses wajib diunggah saat status diproses'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedStatus == 'Selesai' &&
        _fotoBuktiXFile == null &&
        widget.laporan.fotoBukti == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti wajib diunggah jika status Selesai'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resp = await ApiService.updateLaporan(
        widget.laporan.id,
        _selectedStatus,
        _tanggapanCtrl.text.trim(),
        kIsWeb ? _fotoProsesXFile : _fotoProses,
        kIsWeb ? _fotoBuktiXFile : _fotoBukti,
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil diperbarui'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${resp.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.laporan;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Detail Pengaduan'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatLaporanAdminScreen(
                    laporanId: l.id,
                    judulLaporan: l.judul,
                    namaUser: l.namaUser,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat dengan User',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard('Informasi Laporan', [
              _infoRow(Icons.title, 'Judul', l.judul),
              _infoRow(
                  Icons.category_outlined, 'Kategori', l.kategori ?? 'Umum'),
              _infoRow(Icons.description_outlined, 'Deskripsi', l.deskripsi),
              _infoRow(Icons.access_time, 'Tanggal', _formatDate(l.createdAt)),
              if (l.latitude != null && l.longitude != null)
                _locationRow(l.latitude!, l.longitude!),
            ]),
            const SizedBox(height: 12),
            _sectionCard('Data Pelapor', [
              _infoRow(Icons.person_outline, 'Nama',
                  l.namaUser ?? 'Tidak diketahui'),
              if (l.nikUser != null)
                _infoRow(Icons.badge_outlined, 'NIK', l.nikUser!),
              if (l.noHpUser != null)
                _infoRow(Icons.phone_outlined, 'No. HP', l.noHpUser!),
              if (l.emailUser != null)
                _infoRow(Icons.email_outlined, 'Email', l.emailUser!),
            ]),
            const SizedBox(height: 12),
            if (l.fotoPengaduan != null) ...[
              _sectionCard('Foto Bukti Pengaduan', [
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    buildStorageUrl(ApiService.baseUrl, l.fotoPengaduan!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (_, child, prog) => prog == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Foto tidak dapat dimuat',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
                if (l.fotoPengaduanAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Diunggah: ${_formatDate(l.fotoPengaduanAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ]),
              const SizedBox(height: 12),
            ],
            if (l.fotoProses != null) ...[
              _sectionCard('Foto Bukti Sedang Diproses', [
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    buildStorageUrl(ApiService.baseUrl, l.fotoProses!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (_, child, prog) => prog == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Foto tidak dapat dimuat',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
                if (l.fotoProsesAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Diunggah: ${_formatDate(l.fotoProsesAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ]),
              const SizedBox(height: 12),
            ],
            if (l.fotoBukti != null) ...[
              _sectionCard('Foto Bukti Penyelesaian', [
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    buildStorageUrl(ApiService.baseUrl, l.fotoBukti!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (_, child, prog) => prog == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Foto tidak dapat dimuat',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
                if (l.fotoBuktiAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Diselesaikan: ${_formatDate(l.fotoBuktiAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ]),
              const SizedBox(height: 12),
            ],
            _sectionCard('Tindak Lanjut Admin', [
              const SizedBox(height: 4),
              // Status dropdown
              const Text('Status Pengaduan',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: _statusList.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            CircleAvatar(
                                radius: 5, backgroundColor: _statusColor(s)),
                            const SizedBox(width: 8),
                            Text(s),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedStatus = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tanggapan
              const Text('Tanggapan / Catatan',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _tanggapanCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tulis tanggapan admin di sini...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              // Upload foto bukti proses (wajib jika Sedang Diproses)
              if (_selectedStatus == 'Sedang Diproses') ...[
                const SizedBox(height: 16),
                const Text('Foto Bukti Sedang Diproses',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54)),
                const SizedBox(height: 8),
                if (_fotoProsesXFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(
                            _fotoProsesXFile!.path,
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
                            _fotoProses!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  )
                else if (l.fotoProses != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      buildStorageUrl(ApiService.baseUrl, l.fotoProses!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.image, size: 50)),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Text('Belum ada foto dipilih',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(isProcess: true),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pilih Foto Proses'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              // Upload foto bukti (wajib jika Selesai)
              if (_selectedStatus == 'Selesai') ...[
                const SizedBox(height: 16),
                const Text('Foto Bukti Penyelesaian',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54)),
                const SizedBox(height: 8),
                if (_fotoBuktiXFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(
                            _fotoBuktiXFile!.path,
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
                            _fotoBukti!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  )
                else if (l.fotoBukti != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      buildStorageUrl(ApiService.baseUrl, l.fotoBukti!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.image, size: 50)),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Text('Belum ada foto dipilih',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(isProcess: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l.fotoBukti != null && _fotoBuktiXFile == null
                      ? 'Ganti Foto Bukti'
                      : 'Pilih Foto dari Galeri'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _simpan,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: const Text('Simpan Perubahan',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),
          ],
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
                  color: Color(0xFF0D47A1))),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(double latitude, double longitude) {
    final locationText =
        '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          const SizedBox(
            width: 80,
            child: Text('Lokasi:',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locationText,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openMaps(latitude, longitude),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Buka Maps'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${local.day} ${months[local.month]} ${local.year}, '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
