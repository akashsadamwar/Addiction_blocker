import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gj4_accountability/models/user_profile.dart';
import 'package:gj4_accountability/screens/enter_code_screen.dart';
import 'package:gj4_accountability/screens/home_screen.dart';
import 'package:gj4_accountability/screens/login_screen.dart';
import 'package:gj4_accountability/screens/splash_screen.dart';
import 'package:gj4_accountability/services/auth_service.dart';
import 'package:gj4_accountability/services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Gj4App());
}

class Gj4App extends StatelessWidget {
  const Gj4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GJ4 Accountability',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20), brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(
            onLogin: (email, password) async {
              await _auth.signInWithEmail(email, password);
            },
            onSignup: (email, password, displayName) async {
              await _auth.signUpWithEmail(email, password, displayName);
            },
            onSuccess: () {
              if (mounted) setState(() {});
            },
          );
        }
        return HomeWrapper(
          uid: user.uid,
onSignOut: () async {
            await _auth.signOut();
            if (mounted) setState(() {});
          },
        );
      },
    );
  }
}

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key, required this.uid, required this.onSignOut});

  final String uid;
  final VoidCallback onSignOut;

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  UserProfile? _profile;
  UserProfile? _partnerProfile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _firestore.getUserProfile(widget.uid);
    UserProfile? partner;
    if (profile?.partnerId != null) {
      partner = await _firestore.getUserProfile(profile!.partnerId!);
    }
    if (mounted) {
      setState(() {
        _profile = profile;
        _partnerProfile = partner;
        _loading = false;
      });
    }
  }

  void _onLinked(UserProfile linkedUser) {
    setState(() {
      _partnerProfile = linkedUser;
      _profile = _profile?.copyWith(partnerId: linkedUser.uid) ?? _profile;
    });
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_profile == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    return HomeScreen(
      profile: _profile!,
      partnerProfile: _partnerProfile,
      onSignOut: widget.onSignOut,
      onEnterCode: () async {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => EnterCodeScreen(
              partnerUid: widget.uid,
              onLinked: _onLinked,
            ),
          ),
        );
        _load();
      },
    );
  }
}
