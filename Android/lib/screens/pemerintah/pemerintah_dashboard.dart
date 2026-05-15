import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/push_notification_service.dart';
import 'pemerintah_rekap.dart';
import 'pemerintah_laporan_ditugaskan.dart';
import 'pemerintah_arsip_laporan.dart';
import 'pemerintah_profil.dart';

class PemerintahDashboard extends StatefulWidget {
  final String role;

  const PemerintahDashboard({super.key, this.role = 'sekretaris'});

  @override
  State<PemerintahDashboard> createState() => _PemerintahDashboardState();
}

class _PemerintahDashboardState extends State<PemerintahDashboard> {
  int _selectedIndex = 0;
  int _unreadMessages = 0;
  Timer? _messageTimer;
  static const _primaryColor = Color(0xFF1B5E20);

  late final List<Widget> _pages = [
    const PemerintahRekap(),
    const PemerintahLaporanDitugaskan(),
    const PemerintahArsipLaporan(),
    PemerintahProfil(role: widget.role),
  ];

  @override
  void initState() {
    super.initState();
    LocalNotificationService.requestPermission();
    PushNotificationService.syncTokenToServer();
    _loadUnreadMessages();
    _messageTimer = Timer.periodic(
      const Duration(seconds: 3),
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) =>
            setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: _primaryColor.withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon:
                Icon(Icons.analytics, color: _primaryColor),
            label: 'Rekap',
          ),
          NavigationDestination(
            icon: _messageBadge(const Icon(Icons.assignment_outlined)),
            selectedIcon: _messageBadge(
                const Icon(Icons.assignment, color: _primaryColor)),
            label: 'Laporan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.archive_outlined),
            selectedIcon: Icon(Icons.archive, color: _primaryColor),
            label: 'Arsip',
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
