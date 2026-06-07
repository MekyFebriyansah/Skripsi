import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/laporan_model.dart';
import 'laporan_list_screen.dart';
import 'laporan_detail_screen.dart';
import 'admin_kelola_kategori.dart';
import 'admin_manajemen_pengguna.dart';
import 'admin_rekap.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const _primary = Color(0xFF0D47A1);

  String _namaAdmin = 'Admin';
  int _total = 0, _belum = 0, _proses = 0, _selesai = 0;
  List<LaporanModel> _recent = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userData = await ApiService.getUserData();
      final data = await ApiService.getAllLaporan();
      final list = data.map((e) => LaporanModel.fromJson(e)).toList();

      if (!mounted) return;
      setState(() {
        _namaAdmin = userData['name'] ?? 'Admin';
        _total = list.length;
        _belum = list.where((l) => l.status == 'Belum Ditangani').length;
        _proses = list.where((l) => l.status == 'Sedang Diproses').length;
        _selesai = list.where((l) => l.status == 'Selesai').length;
        _recent = list.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selamat Datang,',
                style: TextStyle(fontSize: 13, color: Colors.white70)),
            Text(_namaAdmin,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        _buildStatGrid(),
                        _buildQuickAccess(context),
                        _buildRecentLaporan(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Gagal memuat data',
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: const Text(
        'Panel Admin — Desa Mandiangin Pasar',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  Widget _buildStatGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              _statCard(
                  'Total Laporan Masyarakat',
                  _total,
                  Icons.assignment_rounded,
                  const Color(0xFF1565C0),
                  const Color(0xFFE3F2FD)),
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
                  Icons.warning_amber_rounded,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Akses Cepat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickBtn(context, 'Semua\nLaporan', Icons.list_alt_rounded,
                  const Color(0xFF1565C0), const LaporanListScreen()),
              const SizedBox(width: 10),
              _quickBtn(context, 'Kelola\nKategori', Icons.category_rounded,
                  const Color(0xFF6A1B9A), const AdminKelolaKategori()),
              const SizedBox(width: 10),
              _quickBtn(context, 'Pengguna', Icons.people_alt_rounded,
                  const Color(0xFF00695C), const AdminManajemenPengguna()),
              const SizedBox(width: 10),
              _quickBtn(context, 'Rekap', Icons.bar_chart_rounded,
                  const Color(0xFFE65100), const AdminRekap()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickBtn(BuildContext context, String label, IconData icon,
      Color color, Widget page) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLaporan(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Laporan Terbaru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LaporanListScreen())),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recent.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada laporan.',
                    style: TextStyle(color: Colors.grey)),
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
                    child: Icon(Icons.report_problem_rounded,
                        color: color, size: 20),
                  ),
                  title: Text(l.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                      '${l.kategori ?? "Umum"} • ${l.namaUser ?? "—"}',
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
                            fontWeight: FontWeight.w600)),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LaporanDetailScreen(laporan: l)),
                  ).then((_) => _load()),
                ),
              );
            }),
        ],
      ),
    );
  }
}
