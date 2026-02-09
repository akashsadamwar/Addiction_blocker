import 'package:flutter/material.dart';
import 'package:gj4_accountability/screens/signup_screen.dart';

typedef LoginFn = Future<void> Function(String email, String password);
typedef SignupFn = Future<void> Function(String email, String password, String displayName);

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onSignup,
    required this.onSuccess,
  });

  final LoginFn onLogin;
  final SignupFn onSignup;
  final VoidCallback onSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _error = null; _loading = true; });
    try {
      await widget.onLogin(_emailController.text.trim(), _passwordController.text);
      if (mounted) widget.onSuccess();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst(RegExp(r'\[.*\] '), ''); _loading = false; });
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Text('Sign in', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Use your account to continue', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                  const SizedBox(height: 16),
                ],
                TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com', border: OutlineInputBorder()), validator: (v) { if (v == null || v.trim().isEmpty) return 'Enter your email'; if (!v.contains('@')) return 'Enter a valid email'; return null; }),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), validator: (v) { if (v == null || v.isEmpty) return 'Enter your password'; return null; }),
                const SizedBox(height: 24),
                FilledButton(onPressed: _loading ? null : () { if (_formKey.currentState!.validate()) _submit(); }, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in')),
                const SizedBox(height: 16),
                TextButton(onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignupScreen(onSignup: widget.onSignup, onSuccess: widget.onSuccess))); }, child: const Text("Don't have an account? Sign up")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
