import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/push_notification_service.dart';
import 'admin_dashboard.dart';
import 'laporan_list_screen.dart';
import 'admin_rekap.dart';
import 'admin_profil.dart';
import 'admin_kelola_kategori.dart';
import 'admin_manajemen_pengguna.dart';

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  int _selectedIndex = 0;
  int _unreadMessages = 0;
  Timer? _messageTimer;

  static const _primaryColor = Color(0xFF0D47A1);

  final List<Widget> _pages = [
    const AdminDashboard(),
    const LaporanListScreen(),
    const AdminKelola(),
    const AdminRekap(),
    const AdminProfil(),
  ];

  @override
  void initState() {
    super.initState();
    LocalNotificationService.requestPermission();
    PushNotificationService.syncTokenToServer();
    _loadUnreadMessages();
    _messageTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadUnreadMessages(showNotification: true),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadMessages({bool showNotification = false}) async {
    try {
      final count = await ApiService.getUnreadCount();
      if (!mounted) return;

      final hasNewMessage = showNotification && count > _unreadMessages;
      setState(() => _unreadMessages = count);

      if (hasNewMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 1
                  ? 'Ada 1 pesan baru dari masyarakat'
                  : 'Ada $count pesan baru dari masyarakat',
            ),
            action: SnackBarAction(
              label: 'Lihat',
              onPressed: () => setState(() => _selectedIndex = 1),
            ),
          ),
        );
      }
    } catch (_) {
      // Notifikasi chat tidak boleh membuat halaman utama gagal dibuka.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: _primaryColor.withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _primaryColor),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: _messageBadge(const Icon(Icons.list_alt_outlined)),
            selectedIcon:
                _messageBadge(const Icon(Icons.list_alt, color: _primaryColor)),
            label: 'Laporan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: _primaryColor),
            label: 'Kelola',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: _primaryColor),
            label: 'Rekap',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person, color: _primaryColor),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _messageBadge(Widget child) {
    if (_unreadMessages <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 16),
            child: Text(
              _unreadMessages > 99 ? '99+' : '$_unreadMessages',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tab Kelola (Kategori + Pengguna) ──────────────────────────────────────
class AdminKelola extends StatelessWidget {
  const AdminKelola({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola'),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.category), text: 'Kategori'),
              Tab(icon: Icon(Icons.people), text: 'Pengguna'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminKelolaKategori(),
            AdminManajemenPengguna(),
          ],
        ),
      ),
    );
  }
}
