import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/push_notification_service.dart';
import 'user_dashboard.dart';
import 'pengaduan_form.dart';
import 'user_riwayat.dart';
import 'user_profil.dart';

class UserMain extends StatefulWidget {
  const UserMain({super.key});

  @override
  State<UserMain> createState() => _UserMainState();
}

class _UserMainState extends State<UserMain> {
  int _selectedIndex = 0;
  int _unreadMessages = 0;
  Timer? _messageTimer;
  static const _primaryColor = Color(0xFF1565C0);

  final List<Widget> _pages = [
    const UserDashboard(),
    const UserRiwayat(),
    const UserProfil(),
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
                  ? 'Ada 1 pesan baru dari admin'
                  : 'Ada $count pesan baru dari admin',
            ),
            action: SnackBarAction(
              label: 'Lihat',
              onPressed: () => setState(() => _selectedIndex = 1),
            ),
          ),
        );
      }
    } catch (_) {
      // Notifikasi tidak boleh mengganggu alur utama aplikasi.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex == 0 ? 0 : _selectedIndex + 1,
        onDestinationSelected: (i) {
          // Tab "Buat" selalu push sebagai page baru agar form reset
          if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PengaduanForm()),
            );
            return;
          }
          setState(() => _selectedIndex = i == 0 ? 0 : i - 1);
        },
        backgroundColor: Colors.white,
        indicatorColor: _primaryColor.withOpacity(0.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: _primaryColor),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: _primaryColor),
            label: 'Buat',
          ),
          NavigationDestination(
            icon: _messageBadge(const Icon(Icons.history_outlined)),
            selectedIcon:
                _messageBadge(const Icon(Icons.history, color: _primaryColor)),
            label: 'Riwayat',
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
