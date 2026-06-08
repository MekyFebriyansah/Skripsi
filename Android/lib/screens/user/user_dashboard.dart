import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/laporan_model.dart';
import 'pengaduan_form.dart';
import 'user_riwayat.dart';
import 'user_laporan_detail.dart';
import 'user_notifikasi.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  static const _primary = Color(0xFF1565C0);

  String _namaUser = 'Masyarakat';
  int _total = 0, _belum = 0, _proses = 0, _selesai = 0;
  List<LaporanModel> _recent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final userData = await ApiService.getUserData();
      final response = await ApiService.get('/laporan/saya');
      if (!mounted) return;

      List<LaporanModel> list = [];
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        list = data.map((e) => LaporanModel.fromJson(e)).toList();
      }

      setState(() {
        _namaUser = userData['name'] ?? 'Masyarakat';
        _total = list.length;
        _belum = list.where((l) => l.status == 'Belum Ditangani').length;
        _proses = list.where((l) => l.status == 'Sedang Diproses').length;
        _selesai = list.where((l) => l.status == 'Selesai').length;
        _recent = list.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Halo,',
                style: TextStyle(fontSize: 13, color: Colors.white70)),
            Text(_namaUser,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UserNotifikasi())),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    _buildStatCards(),
                    _buildRecentSection(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Sampaikan keluhan Anda kepada kami',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PengaduanForm()))
                  .then((_) => _load()),
              icon: const Icon(Icons.add_circle_outline, size: 22),
              label: const Text('BUAT PENGADUAN BARU',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _statCard('Total Laporan Anda', _total, Icons.assignment_rounded,
                  const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
              const SizedBox(width: 12),
              _statCard(
                  'Laporan Selesai Ditangani',
                  _selesai,
                  Icons.check_circle_rounded,
                  const Color(0xFF2E7D32),
                  const Color(0xFFE8F5E9)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                  'Laporan Sedang Diproses',
                  _proses,
                  Icons.hourglass_bottom_rounded,
                  const Color(0xFFE65100),
                  const Color(0xFFFFF3E0)),
              const SizedBox(width: 12),
              _statCard(
                  'Laporan Belum Ditangani',
                  _belum,
                  Icons.pending_rounded,
                  const Color(0xFFC62828),
                  const Color(0xFFFFEBEE)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, int value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pengaduan Terbaru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UserRiwayat())),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recent.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text('Belum ada pengaduan',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PengaduanForm())),
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Pengaduan Pertama'),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_recent.length, (i) {
              final l = _recent[i];
              final color = _statusColor(l.status);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(Icons.report_rounded, color: color, size: 20),
                  ),
                  title: Text(l.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(l.kategori ?? 'Umum',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(l.status,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => UserLaporanDetail(laporan: l)),
                  ).then((_) => _load()),
                ),
              );
            }),
        ],
      ),
    );
  }
}
