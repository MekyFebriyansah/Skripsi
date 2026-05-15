import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PengaturanNotifikasi extends StatefulWidget {
  const PengaturanNotifikasi({super.key});

  @override
  State<PengaturanNotifikasi> createState() => _PengaturanNotifikasiState();
}

class _PengaturanNotifikasiState extends State<PengaturanNotifikasi> {
  static const _primary = Color(0xFF1565C0);

  bool _notifStatus = true;
  bool _notifChat = true;
  bool _notifStatusUpdate = true;
  bool _notifSelesai = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifStatus = prefs.getBool('notif_push') ?? true;
      _notifChat = prefs.getBool('notif_chat') ?? true;
      _notifStatusUpdate = prefs.getBool('notif_status_update') ?? true;
      _notifSelesai = prefs.getBool('notif_selesai') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Pengaturan Notifikasi"),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.notifications_active_outlined,
                            color: _primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Kelola jenis notifikasi yang ingin Anda terima dari aplikasi.',
                            style: TextStyle(fontSize: 13, color: _primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                      children: [
                        SwitchListTile(
                          title: const Text("Notifikasi Push",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle:
                              const Text("Aktifkan/nonaktifkan semua notifikasi"),
                          value: _notifStatus,
                          onChanged: (v) {
                            setState(() => _notifStatus = v);
                            _save('notif_push', v);
                          },
                          activeColor: _primary,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          title: const Text("Pesan Chat"),
                          subtitle: const Text(
                              "Notifikasi saat ada pesan baru dari petugas"),
                          value: _notifChat && _notifStatus,
                          onChanged: _notifStatus
                              ? (v) {
                                  setState(() => _notifChat = v);
                                  _save('notif_chat', v);
                                }
                              : null,
                          activeColor: _primary,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          title: const Text("Update Status Laporan"),
                          subtitle: const Text(
                              "Notifikasi saat status pengaduan berubah"),
                          value: _notifStatusUpdate && _notifStatus,
                          onChanged: _notifStatus
                              ? (v) {
                                  setState(() => _notifStatusUpdate = v);
                                  _save('notif_status_update', v);
                                }
                              : null,
                          activeColor: _primary,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          title: const Text("Laporan Selesai"),
                          subtitle: const Text(
                              "Notifikasi saat pengaduan telah diselesaikan"),
                          value: _notifSelesai && _notifStatus,
                          onChanged: _notifStatus
                              ? (v) {
                                  setState(() => _notifSelesai = v);
                                  _save('notif_selesai', v);
                                }
                              : null,
                          activeColor: _primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      "Notifikasi menggunakan Firebase Cloud Messaging (FCM)",
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
