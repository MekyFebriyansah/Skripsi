import 'package:flutter/material.dart';
import '../../models/laporan_model.dart';
import '../../services/api_service.dart';
import 'chat_laporan_screen.dart';

class UserLaporanDetail extends StatelessWidget {
  final LaporanModel laporan;
  const UserLaporanDetail({super.key, required this.laporan});

  static const _primary = Color(0xFF1565C0);

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

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Selesai':
        return Icons.check_circle_rounded;
      case 'Sedang Diproses':
        return Icons.hourglass_bottom_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${local.day} ${months[local.month]} ${local.year}, '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(laporan.status);

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
                  builder: (_) => ChatLaporanScreen(
                    laporanId: laporan.id,
                    judulLaporan: laporan.judul,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat dengan Admin',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(_statusIcon(laporan.status),
                        color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          laporan.status,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color),
                        ),
                        Text(
                          laporan.status == 'Selesai'
                              ? 'Pengaduan Anda telah selesai ditangani.'
                              : laporan.status == 'Sedang Diproses'
                                  ? 'Pengaduan Anda sedang ditindaklanjuti.'
                                  : 'Pengaduan Anda menunggu penanganan.',
                          style: TextStyle(
                              fontSize: 12,
                              color: color.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Detail Laporan
            _card('Detail Pengaduan', [
              _row(Icons.title, 'Judul', laporan.judul),
              _row(Icons.category_outlined, 'Kategori',
                  laporan.kategori ?? 'Umum'),
              _row(Icons.access_time, 'Tanggal',
                  _formatDate(laporan.createdAt)),
              if (laporan.latitude != null)
                _row(Icons.location_on_outlined, 'Lokasi',
                    '${laporan.latitude!.toStringAsFixed(6)}, ${laporan.longitude!.toStringAsFixed(6)}'),
              const Divider(height: 16),
              const Text('Deskripsi',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 6),
              Text(laporan.deskripsi,
                  style:
                      const TextStyle(fontSize: 14, height: 1.5)),
            ]),
            const SizedBox(height: 12),

            // Tanggapan Admin
            _card('Tanggapan Admin', [
              if (laporan.tanggapan == null ||
                  laporan.tanggapan!.isEmpty)
                Row(
                  children: [
                    Icon(Icons.hourglass_empty,
                        size: 18, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    const Text(
                      'Belum ada tanggapan dari admin.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.forum_outlined,
                          color: _primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          laporan.tanggapan!,
                          style: const TextStyle(
                              fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ]),

            if (laporan.fotoPengaduan != null) ...[
              const SizedBox(height: 12),
              _card('Foto Bukti Pengaduan', [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    buildStorageUrl(ApiService.baseUrl, laporan.fotoPengaduan!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (_, child, prog) =>
                        prog == null
                            ? child
                            : const SizedBox(
                                height: 150,
                                child: Center(
                                    child:
                                        CircularProgressIndicator())),
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Foto tidak dapat dimuat',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
                if (laporan.fotoPengaduanAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Diunggah: ${_formatDate(laporan.fotoPengaduanAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ]),
            ],
            if (laporan.fotoProses != null) ...[
              const SizedBox(height: 12),
              _card('Foto Bukti Sedang Diproses', [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    buildStorageUrl(ApiService.baseUrl, laporan.fotoProses!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (_, child, prog) =>
                        prog == null
                            ? child
                            : const SizedBox(
                                height: 150,
                                child: Center(
                                    child:
                                        CircularProgressIndicator())),
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Foto tidak dapat dimuat',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
                if (laporan.fotoProsesAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Diunggah: ${_formatDate(laporan.fotoProsesAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ]),
            ],
            if (laporan.fotoBukti != null) ...[
              const SizedBox(height: 12),
              _card('Foto Bukti Penyelesaian', [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    buildStorageUrl(ApiService.baseUrl, laporan.fotoBukti!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (_, child, prog) =>
                        prog == null
                            ? child
                            : const SizedBox(
                                height: 150,
                                child: Center(
                                    child:
                                        CircularProgressIndicator())),
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Foto tidak dapat dimuat',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
                if (laporan.fotoBuktiAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Diunggah: ${_formatDate(laporan.fotoBuktiAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ]),
            ],
            const SizedBox(height: 24),

            // Timeline Status
            _card('Alur Status Pengaduan', [
              _timelineItem(
                'Pengaduan Dikirim',
                _formatDate(laporan.createdAt),
                true,
                Colors.blue,
              ),
              _timelineItem(
                'Sedang Diproses',
                laporan.status == 'Sedang Diproses' ||
                        laporan.status == 'Selesai'
                    ? (laporan.fotoProsesAt != null
                        ? _formatDate(laporan.fotoProsesAt!)
                        : 'Sudah dilakukan')
                    : 'Menunggu...',
                laporan.status == 'Sedang Diproses' ||
                    laporan.status == 'Selesai',
                Colors.orange,
              ),
              _timelineItem(
                'Selesai Ditangani',
                laporan.status == 'Selesai'
                    ? (laporan.fotoBuktiAt != null
                        ? _formatDate(laporan.fotoBuktiAt!)
                        : 'Sudah selesai')
                    : 'Belum',
                laporan.status == 'Selesai',
                Colors.green,
                isLast: true,
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
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

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(
      String label, String sub, bool done, Color color,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: done ? color : Colors.grey.shade300,
              child: done
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                  width: 2,
                  height: 32,
                  color: done ? color.withOpacity(0.3) : Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: done ? Colors.black87 : Colors.grey)),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45)),
            ],
          ),
        ),
      ],
    );
  }
}
