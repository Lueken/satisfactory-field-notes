import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/game_data_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'alternates_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final gameData = ref.watch(gameDataProvider);
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Settings',
            style: TextStyle(fontSize: 16, fontFamily: 'ShareTechMono')),
        toolbarHeight: 48,
      ),
      body: gameData.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: ficsitAmber)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final alternates = data.recipes.values
              .where((r) => r.alternate && r.inMachine && !r.forBuilding)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionLabel('GAME TIER'),
              const SizedBox(height: 8),
              _TierSelector(
                label: 'Belt tier',
                value: settings.beltTier,
                options: const [1, 2, 3, 4, 5, 6],
                labels: const ['Mk.1 (60)', 'Mk.2 (120)', 'Mk.3 (270)', 'Mk.4 (480)', 'Mk.5 (780)', 'Mk.6 (1200)'],
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setBeltTier(v),
              ),
              const SizedBox(height: 10),
              _TierSelector(
                label: 'Miner tier',
                value: settings.minerTier,
                options: const [1, 2, 3],
                labels: const ['Mk.1', 'Mk.2', 'Mk.3'],
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setMinerTier(v),
              ),

              const SizedBox(height: 24),
              _SectionLabel('APPEARANCE'),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Dark mode',
                subtitle: 'Easier on pioneer eyes at night',
                value: settings.darkMode,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  ref.read(settingsProvider.notifier).setDarkMode(v);
                },
              ),

              const SizedBox(height: 24),
              _SectionLabel('MODIFIERS'),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Overclocking',
                subtitle: 'Allow overclock adjustments',
                value: settings.overclockingEnabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(settingsProvider.notifier)
                      .setOverclocking(v);
                },
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Somersloop',
                subtitle: '2x production, higher power',
                value: settings.somersloopEnabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  ref.read(settingsProvider.notifier).setSomersloop(v);
                },
              ),

              const SizedBox(height: 24),
              _SectionLabel('RESEARCH'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AlternatesScreen()),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colors.borderSecondary, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science_outlined,
                          size: 18, color: ficsitAmber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alternate recipes',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: colors.textPrimary,
                                    fontFamily: 'ShareTechMono')),
                            Text(
                              '${settings.unlockedAlternates.length} of ${alternates.length} unlocked',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 20, color: colors.textTertiary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              _SectionLabel('SUPPORT THE APP'),
              const SizedBox(height: 8),
              Text(
                'FICSIT Field Notes is free. If it saves you time, consider tossing a few credits to the engineer.',
                style: TextStyle(
                    fontSize: 12,
                    color: colors.textTertiary,
                    height: 1.5),
              ),
              const SizedBox(height: 12),
              _LinkRow(
                icon: Icons.coffee,
                label: 'Ko-Fi',
                subtitle: 'ko-fi.com/lgdllc',
                onTap: () => launchUrl(
                    Uri.parse('https://ko-fi.com/lgdllc'),
                    mode: LaunchMode.externalApplication),
              ),
              const SizedBox(height: 8),
              _BitcoinAddressRow(
                address: 'bc1qg2jqdlrtkfqkggwfg25xr2s57vcjpf03hymjxr',
              ),

              const SizedBox(height: 32),
              _SectionLabel('LEGAL'),
              const SizedBox(height: 8),
              _LinkRow(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                onTap: () => launchUrl(
                    Uri.parse(
                        'https://lueken-good.design/ficsit-field-notes/terms'),
                    mode: LaunchMode.externalApplication),
              ),
              const SizedBox(height: 8),
              _LinkRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => launchUrl(
                    Uri.parse(
                        'https://lueken-good.design/ficsit-field-notes/privacy'),
                    mode: LaunchMode.externalApplication),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'FICSIT Field Notes  ·  v0.1.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textTertiary,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Unofficial fan project · Not affiliated with Coffee Stain Studios',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSecondary, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ficsitAmber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                          fontFamily: 'ShareTechMono')),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 11, color: colors.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.open_in_new,
                size: 14, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _BitcoinAddressRow extends StatelessWidget {
  final String address;
  const _BitcoinAddressRow({required this.address});

  Future<void> _openInWallet(BuildContext context) async {
    final uri = Uri.parse('bitcoin:$address');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _copy(context);
    }
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: address));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bitcoin address copied'),
        backgroundColor: ficsitAmber,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSecondary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_bitcoin,
                  size: 18, color: ficsitAmber),
              const SizedBox(width: 8),
              Text(
                'Bitcoin',
                style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                    fontFamily: 'ShareTechMono'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tappable address chip
          InkWell(
            onTap: () => _openInWallet(context),
            onLongPress: () => _copy(context),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bgTertiary,
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: colors.borderSecondary, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copy(context),
                    child: Icon(Icons.copy,
                        size: 14, color: colors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to open in wallet · long-press or copy icon to copy',
            style: TextStyle(
                fontSize: 10, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: colors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _TierSelector extends StatelessWidget {
  final String label;
  final int value;
  final List<int> options;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _TierSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(label,
              style: TextStyle(fontSize: 14, color: colors.textPrimary)),
        ),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            initialValue: value,
            isDense: true,
            decoration: const InputDecoration(isDense: true),
            style: TextStyle(fontSize: 14, color: colors.textPrimary, fontFamily: 'ShareTechMono'),
            dropdownColor: colors.bgSecondary,
            items: [
              for (var i = 0; i < options.length; i++)
                DropdownMenuItem(value: options[i], child: Text(labels[i])),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 14, color: colors.textPrimary)),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 12, color: colors.textTertiary)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: ficsitAmber,
        ),
      ],
    );
  }
}

