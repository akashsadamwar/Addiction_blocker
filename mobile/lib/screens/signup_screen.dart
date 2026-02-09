import 'package:flutter/material.dart';

typedef SignupFn = Future<void> Function(String email, String password, String displayName);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.onSignup, required this.onSuccess});

  final SignupFn onSignup;
  final VoidCallback onSuccess;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _error = null; _loading = true; });
    try {
      await widget.onSignup(_emailController.text.trim(), _passwordController.text, _nameController.text.trim());
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
      appBar: AppBar(title: const Text('Sign up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                  const SizedBox(height: 16),
                ],
                TextFormField(controller: _nameController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Display name', hintText: 'How your partner will see you', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com', border: OutlineInputBorder()), validator: (v) { if (v == null || v.trim().isEmpty) return 'Enter your email'; if (!v.contains('@')) return 'Enter a valid email'; return null; }),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', hintText: 'At least 6 characters', border: OutlineInputBorder()), validator: (v) { if (v == null || v.isEmpty) return 'Enter a password'; if (v.length < 6) return 'Use at least 6 characters'; return null; }),
                const SizedBox(height: 24),
                FilledButton(onPressed: _loading ? null : () { if (_formKey.currentState!.validate()) _submit(); }, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create account')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
