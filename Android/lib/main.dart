import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/local_notification_service.dart';
import 'services/push_notification_service.dart';
import 'screens/admin/admin_main.dart';
import 'screens/landing_page.dart';
import 'screens/pemerintah/pemerintah_dashboard.dart';
import 'screens/user/user_main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.initialize();
  await PushNotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelaporan Keluhan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _goTo(const LandingPage());
      return;
    }

    try {
      final profile = await ApiService.getProfile();
      if (profile == null) {
        await ApiService.logout();
        _goTo(const LandingPage());
        return;
      }

      await ApiService.saveUserData(profile);
      final role = profile['role'];
      if (role == 'admin') {
        _goTo(const AdminMain());
      } else if (role == 'sekretaris' || role == 'kepala_desa') {
        _goTo(PemerintahDashboard(role: role));
      } else {
        _goTo(const UserMain());
      }
    } catch (_) {
      await ApiService.logout();
      _goTo(const LandingPage());
    }
  }

  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}