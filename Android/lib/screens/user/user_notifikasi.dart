import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/laporan_model.dart';
import 'user_laporan_detail.dart';
import 'chat_laporan_screen.dart';

class UserNotifikasi extends StatefulWidget {
  const UserNotifikasi({super.key});

  @override
  State<UserNotifikasi> createState() => _UserNotifikasiState();
}

class _UserNotifikasiState extends State<UserNotifikasi> {
  static const _primary = Color(0xFF1565C0);

  List<_NotifItem> _items = [];
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
      final resp = await ApiService.get('/laporan/saya');
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        final laporanList =
            data.map((e) => LaporanModel.fromJson(e)).toList();
        laporanList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final laporanById = {for (final l in laporanList) l.id: l};

        final notifs = <_NotifItem>[];
        for (final l in laporanList) {
          if (l.status == 'Selesai') {
            notifs.add(_NotifItem(
              title: 'Pengaduan Telah Selesai',
              message:
                  'Laporan "${l.judul}" telah selesai ditangani oleh petugas.',
              time: l.fotoBuktiAt ?? l.createdAt,
              type: 'completed',
              laporan: l,
              destination: 'detail',
            ));
          }
          if (l.status == 'Sedang Diproses') {
            notifs.add(_NotifItem(
              title: 'Pengaduan Sedang Diproses',
              message:
                  'Laporan "${l.judul}" sedang ditindaklanjuti oleh petugas.',
              time: l.fotoProsesAt ?? l.createdAt,
              type: 'status',
              laporan: l,
              destination: 'detail',
            ));
          }
          if (l.tanggapan != null && l.tanggapan!.isNotEmpty) {
            notifs.add(_NotifItem(
              title: 'Tanggapan dari Admin',
              message: '"${l.judul}" — ${l.tanggapan}',
              time: l.createdAt,
              type: 'reply',
              laporan: l,
              destination: 'detail',
            ));
          }
        }

        try {
          final chatData = await ApiService.getPesanNotifikasi();
          for (final raw in chatData) {
            final item = raw as Map<String, dynamic>;
            final laporanId = _toInt(item['laporan_id']);
            if (laporanId == null) continue;

            final laporan = laporanById[laporanId];
            final judul = laporan?.judul ??
                (item['judul_laporan']?.toString() ?? 'Laporan');
            final unreadCount = _toInt(item['unread_count']) ?? 1;
            final pengirim = item['pengirim_nama']?.toString();
            final role = item['pengirim_role']?.toString() ?? 'admin';
            final pesan = item['pesan']?.toString() ?? '';

            notifs.add(_NotifItem(
              title: unreadCount > 1
                  ? '$unreadCount pesan baru dari ${pengirim ?? _roleLabel(role)}'
                  : 'Pesan baru dari ${pengirim ?? _roleLabel(role)}',
              message: '"$judul" — $pesan',
              time: _parseDate(item['created_at']) ?? DateTime.now(),
              type: 'chat',
              laporan: laporan,
              laporanId: laporanId,
              judulLaporan: judul,
              destination: 'chat',
            ));
          }
        } catch (_) {
          // Notifikasi status laporan tetap ditampilkan walaupun data chat gagal.
        }

        notifs.sort((a, b) => b.time.compareTo(a.time));

        setState(() {
          _items = notifs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat notifikasi';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'sekretaris':
        return 'Sekretaris';
      case 'kepala_desa':
        return 'Kepala Desa';
      default:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text("Belum ada notifikasi",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _buildCard(_items[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(_NotifItem item) {
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
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _getColor(item.type).withOpacity(0.15),
          child: Icon(_getIcon(item.type), color: _getColor(item.type)),
        ),
        title: Text(item.title,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(_timeAgo(item.time),
                style:
                    const TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
        onTap: () {
          if (item.destination == 'chat' && item.laporanId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatLaporanScreen(
                  laporanId: item.laporanId!,
                  judulLaporan: item.judulLaporan ??
                      item.laporan?.judul ??
                      'Laporan',
                ),
              ),
            ).then((_) => _load());
          } else if (item.laporan != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      UserLaporanDetail(laporan: item.laporan!)),
            ).then((_) => _load());
          }
        },
      ),
    );
  }

  Color _getColor(String type) {
    switch (type) {
      case 'completed':
        return const Color(0xFF43A047);
      case 'status':
        return const Color(0xFFFF8F00);
      case 'reply':
        return _primary;
      case 'chat':
        return const Color(0xFF00897B);
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'status':
        return Icons.hourglass_bottom_rounded;
      case 'reply':
        return Icons.reply_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications;
    }
  }
}

class _NotifItem {
  final String title;
  final String message;
  final DateTime time;
  final String type;
  final LaporanModel? laporan;
  final int? laporanId;
  final String? judulLaporan;
  final String destination;

  _NotifItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.laporan,
    this.laporanId,
    this.judulLaporan,
    this.destination = 'detail',
  });
}
