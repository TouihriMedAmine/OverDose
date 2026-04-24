import 'package:flutter/material.dart';

import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TunisiaProductApp());
}

class TunisiaProductApp extends StatelessWidget {
  const TunisiaProductApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tunisia Product Search',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AuthService _auth = AuthService();
  UserModel? _user;
  bool _loading = true;
  bool _showLanding = true;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    UserModel? u;
    try {
      u = await _auth.loadMe();
    } catch (_) {
      // Keep app usable even if backend is down at startup.
      u = null;
    }
    if (!mounted) return;
    setState(() {
      _user = u;
      _loading = false;
    });
  }

  void _onLoggedIn() {
    _auth.loadMe().then((u) {
      if (!mounted) return;
      setState(() {
        _user = u;
        _showRegister = false;
      });
    });
  }

  void _onLogout() async {
    await _auth.logout();
    if (!mounted) return;
    setState(() => _user = null);
  }

  Future<void> _refreshUser() async {
    final u = await _auth.loadMe();
    if (!mounted || u == null) return;
    setState(() => _user = u);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showLanding) {
      return LandingScreen(
        onGetStarted: () {
          setState(() {
            _showLanding = false;
            if (_user == null) {
              _showRegister = false; // Go to login page for guests
            }
          });
        },
      );
    }

    if (_user != null) {
      return HomeScreen(
        user: _user!,
        auth: _auth,
        onLogout: _onLogout,
        onProfileSaved: _refreshUser,
      );
    }

    if (_showRegister) {
      return RegisterScreen(
        auth: _auth,
        onRegistered: _onLoggedIn,
        onBackToLogin: () => setState(() => _showRegister = false),
      );
    }

    return LoginScreen(
      auth: _auth,
      onLoggedIn: _onLoggedIn,
      onRegister: () => setState(() => _showRegister = true),
    );
  }
}
