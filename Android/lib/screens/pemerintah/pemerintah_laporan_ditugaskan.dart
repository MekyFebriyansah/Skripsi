import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/laporan_model.dart';
import '../admin/laporan_detail_screen.dart';

class PemerintahLaporanDitugaskan extends StatefulWidget {
  const PemerintahLaporanDitugaskan({super.key});

  @override
  State<PemerintahLaporanDitugaskan> createState() =>
      _PemerintahLaporanDitugaskanState();
}

class _PemerintahLaporanDitugaskanState
    extends State<PemerintahLaporanDitugaskan> {
  static const _primary = Color(0xFF1B5E20);

  List<LaporanModel> _all = [];
  List<LaporanModel> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'Aktif';
  String _search = '';
  final _searchCtrl = TextEditingController();

  final _statusOptions = [
    'Semua',
    'Aktif',
    'Belum Ditangani',
    'Sedang Diproses',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getAllLaporan();
      if (!mounted) return;
      final list = data.map((e) => LaporanModel.fromJson(e)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _all = list;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _humanizeError(e);
          _isLoading = false;
        });
      }
    }
  }

  String _humanizeError(Object e) {
    final s = e.toString();
    if (s.contains('Failed host lookup') || s.contains('SocketException')) {
      return 'Tidak dapat terhubung ke server. Pastikan HP & laptop dalam jaringan yang sama, dan Laragon aktif.';
    }
    if (s.contains('TimeoutException')) {
      return 'Koneksi ke server timeout. Coba lagi atau cek konfigurasi server.';
    }
    if (s.contains('401') || s.toLowerCase().contains('unauthorized')) {
      return 'Sesi habis. Silakan login ulang.';
    }
    return 'Gagal memuat data: $s';
  }

  void _applyFilter() {
    setState(() {
      _filtered = _all.where((l) {
        bool matchStatus;
        switch (_filterStatus) {
          case 'Aktif':
            matchStatus = l.status != 'Selesai';
            break;
          case 'Semua':
            matchStatus = true;
            break;
          default:
            matchStatus = l.status == _filterStatus;
        }
        final q = _search.toLowerCase();
        final matchSearch = q.isEmpty ||
            l.judul.toLowerCase().contains(q) ||
            (l.namaUser ?? '').toLowerCase().contains(q) ||
            (l.kategori ?? '').toLowerCase().contains(q);
        return matchStatus && matchSearch;
      }).toList();
    });
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
        title: const Text('Daftar Laporan'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildFilterChips(),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        onChanged: (v) {
          _search = v;
          _applyFilter();
        },
        decoration: InputDecoration(
          hintText: 'Cari judul, pelapor, kategori...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search = '';
                    _applyFilter();
                  })
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((s) {
            final selected = _filterStatus == s;
            final count = s == 'Aktif'
                ? _all.where((l) => l.status != 'Selesai').length
                : s == 'Semua'
                    ? _all.length
                    : _all.where((l) => l.status == s).length;
            Color c;
            switch (s) {
              case 'Aktif':
                c = _primary;
                break;
              case 'Semua':
                c = Colors.blueGrey;
                break;
              case 'Sedang Diproses':
                c = const Color(0xFFFF8F00);
                break;
              case 'Selesai':
                c = const Color(0xFF43A047);
                break;
              default:
                c = const Color(0xFFE53935);
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected,
                label: Text('$s ($count)'),
                selectedColor: c.withOpacity(0.18),
                checkmarkColor: c,
                labelStyle: TextStyle(
                    color: selected ? c : Colors.black54,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12),
                onSelected: (_) {
                  setState(() => _filterStatus = s);
                  _applyFilter();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
      ]));
    }
    if (_filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _all.isEmpty
                  ? 'Belum ada laporan masuk'
                  : (_search.isNotEmpty
                      ? 'Tidak ada hasil untuk "$_search"'
                      : 'Tidak ada laporan dengan status "$_filterStatus"'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Muat ulang'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filtered.length,
        itemBuilder: (ctx, i) => _buildCard(ctx, _filtered[i]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, LaporanModel l) {
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LaporanDetailScreen(laporan: l)),
        ).then((_) => _load()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Container(
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
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.category_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(l.kategori ?? 'Umum',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(width: 16),
                const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(l.namaUser ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(_fmtDate(l.createdAt),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${dt.day} ${m[dt.month]} ${dt.year}';
  }
}
