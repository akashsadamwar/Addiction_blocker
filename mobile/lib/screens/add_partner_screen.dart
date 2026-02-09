import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gj4_accountability/services/pairing_service.dart';

class AddPartnerScreen extends StatefulWidget {
  const AddPartnerScreen({super.key, required this.uid});

  final String uid;

  @override
  State<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

class _AddPartnerScreenState extends State<AddPartnerScreen> {
  final _pairingService = PairingService();
  String? _code;
  bool _loading = false;
  String? _error;

  Future<void> _generateCode(String uid) async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final code = await _pairingService.generateCode(uid);
      if (mounted) setState(() {
        _code = code;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add partner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share this code with your accountability partner. They enter it in the app to connect. Code expires in 10 minutes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
              const SizedBox(height: 16),
            ],
            if (_code == null) ...[
              FilledButton(
                onPressed: _loading ? null : () => _generateCode(widget.uid),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Generate code'),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _code!,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            letterSpacing: 12,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _code!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => _generateCode(widget.uid),
                          child: const Text('New code'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
