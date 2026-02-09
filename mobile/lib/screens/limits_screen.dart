import 'package:flutter/material.dart';
import 'package:gj4_accountability/models/limit_rule.dart';
import 'package:gj4_accountability/services/firestore_service.dart';

class LimitsScreen extends StatefulWidget {
  const LimitsScreen({super.key, required this.uid});
  final String uid;

  @override
  State<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends State<LimitsScreen> {
  final _firestore = FirestoreService();
  List<LimitRule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = await _firestore.getLimitRules(widget.uid);
    if (mounted) setState(() { _rules = rules; _loading = false; });
  }

  Future<void> _addRule(BuildContext context) async {
    final result = await showDialog<LimitRule>(context: context, builder: (context) => _AddLimitDialog());
    if (result != null) {
      await _firestore.setLimitRule(widget.uid, result);
      _load();
    }
  }

  Future<void> _deleteRule(LimitRule rule) async {
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Remove limit?'), content: Text('Remove limit for ${rule.appDisplayName.isEmpty ? rule.appPackageOrCategory : rule.appDisplayName}?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove'))]));
    if (confirm == true && rule.id != null) {
      await _firestore.setLimitRule(widget.uid, rule.copyWith(active: false));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limits'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _addRule(context))]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No limits yet', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Add a limit to get notified when you exceed it. Your partner will receive the message you set.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 24),
                        FilledButton.icon(onPressed: () => _addRule(context), icon: const Icon(Icons.add), label: const Text('Add limit')),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rules.length,
                  itemBuilder: (context, i) {
                    final r = _rules[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(r.appDisplayName.isEmpty ? r.appPackageOrCategory : r.appDisplayName),
                        subtitle: Text('${r.minutesAllowed} min in ${r.windowMinutes ~/ 60} hr · "${r.shameMessage}"', maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteRule(r)),
                      ),
                    );
                  },
                ),
    );
  }
}

class _AddLimitDialog extends StatefulWidget {
  @override
  State<_AddLimitDialog> createState() => _AddLimitDialogState();
}

class _AddLimitDialogState extends State<_AddLimitDialog> {
  final _appController = TextEditingController(text: 'Instagram');
  final _packageController = TextEditingController(text: 'com.instagram.android');
  final _minutesController = TextEditingController(text: '30');
  final _windowController = TextEditingController(text: '180');
  final _shameController = TextEditingController(text: 'has exceeded their time limit.');

  @override
  void dispose() {
    _appController.dispose();
    _packageController.dispose();
    _minutesController.dispose();
    _windowController.dispose();
    _shameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add limit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _appController, decoration: const InputDecoration(labelText: 'App name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _packageController, decoration: const InputDecoration(labelText: 'Package / category', hintText: 'e.g. com.instagram.android', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _minutesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes allowed', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _windowController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Window (minutes)', hintText: 'e.g. 180 = 3 hours', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _shameController, maxLines: 2, decoration: const InputDecoration(labelText: 'Message to partner', hintText: 'e.g. is doom-scrolling again.', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final rule = LimitRule(
              appPackageOrCategory: _packageController.text.trim().isEmpty ? _appController.text.trim() : _packageController.text.trim(),
              appDisplayName: _appController.text.trim().isEmpty ? 'App' : _appController.text.trim(),
              minutesAllowed: int.tryParse(_minutesController.text) ?? 30,
              windowMinutes: int.tryParse(_windowController.text) ?? 180,
              shameMessage: _shameController.text.trim().isEmpty ? 'has exceeded their time limit.' : _shameController.text.trim(),
            );
            Navigator.pop(context, rule);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
