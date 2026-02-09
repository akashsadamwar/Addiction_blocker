import 'package:flutter/material.dart';
import 'package:gj4_accountability/models/user_profile.dart';
import 'package:gj4_accountability/services/pairing_service.dart';

class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key, required this.partnerUid, required this.onLinked});
  final String partnerUid;
  final void Function(UserProfile linkedUser) onLinked;

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final _pairingService = PairingService();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim().replaceAll(' ', '');
    if (code.length != 6) { setState(() => _error = 'Enter the 6-digit code'); return; }
    setState(() { _error = null; _loading = true; });
    try {
      final profile = await _pairingService.enterCodeAsPartner(code, widget.partnerUid);
      if (!mounted) return;
      if (profile == null) { setState(() { _error = 'Invalid or expired code. Ask your friend for a new one.'; _loading = false; }); return; }
      widget.onLinked(profile);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter code')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter the 6-digit code your friend shared with you.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
              const SizedBox(height: 16),
            ],
            TextField(controller: _codeController, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 8), decoration: const InputDecoration(hintText: '000000', counterText: '', border: OutlineInputBorder()), onChanged: (_) => setState(() => _error = null)),
            const SizedBox(height: 24),
            FilledButton(onPressed: _loading ? null : _submit, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Connect')),
          ],
        ),
      ),
    );
  }
}
