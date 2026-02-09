import 'package:flutter/material.dart';
import 'package:gj4_accountability/models/user_profile.dart';
import 'package:gj4_accountability/screens/add_partner_screen.dart';
import 'package:gj4_accountability/screens/limits_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.partnerProfile,
    required this.onSignOut,
    this.onEnterCode,
  });

  final UserProfile profile;
  final UserProfile? partnerProfile;
  final VoidCallback onSignOut;
  final VoidCallback? onEnterCode;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.displayName.isEmpty ? profile.email.split('@').first : profile.displayName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('GJ4'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => _showSettings(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hi, $displayName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (profile.streakDays > 0)
              Chip(
                avatar: const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                label: Text('${profile.streakDays} day streak'),
              ),
            const SizedBox(height: 32),
            _Section(
              title: 'Accountability partner',
              child: partnerProfile == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Add a friend who gets notified when you exceed your limits.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddPartnerScreen(uid: profile.uid),
                            ),
                          ),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add partner'),
                        ),
                        if (onEnterCode != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: onEnterCode,
                            icon: const Icon(Icons.link),
                            label: const Text('I have a code'),
                          ),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            child: Text((partnerProfile!.displayName.isNotEmpty
                                    ? partnerProfile!.displayName
                                    : partnerProfile!.email)
                                .substring(0, 1)
                                .toUpperCase()),
                          ),
                          title: Text(partnerProfile!.displayName.isEmpty
                              ? partnerProfile!.email
                              : partnerProfile!.displayName),
                          subtitle: const Text('Connected'),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Limits',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Set how long you can use apps before your partner is notified.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LimitsScreen(uid: profile.uid),
                      ),
                    ),
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Manage limits'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.pop(context);
                onSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
