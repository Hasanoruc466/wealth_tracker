import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/theme.dart';
import '../state/providers.dart';
import 'inputs.dart';

/// Sayfa başlığındaki görünüm butonu: tutarları gizleme ve tema seçimi.
class ViewOptionsButton extends StatelessWidget {
  const ViewOptionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) => const _ViewOptionsSheet(),
      ),
      tooltip: 'Görünüm',
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      color: context.palette.muted,
      icon: const Icon(Icons.tune_rounded),
    );
  }
}

class _ViewOptionsSheet extends ConsumerWidget {
  const _ViewOptionsSheet();

  static const _themes = {
    ThemeMode.light: 'Açık',
    ThemeMode.dark: 'Koyu',
    ThemeMode.system: 'Sistem',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final hidden = ref.watch(hideBalancesProvider);
    final mode = ref.watch(themeModeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Görünüm', style: context.text.titleLarge),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: hidden,
              onChanged: (_) {
                HapticFeedback.selectionClick();
                ref.read(hideBalancesProvider.notifier).toggle();
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Tutarları gizle',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Toplam değere dokunarak da açıp kapatabilirsin.',
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tema',
                style: TextStyle(
                    color: palette.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Segmented<ThemeMode>(
              values: _themes.keys.toList(),
              value: mode,
              label: (m) => _themes[m]!,
              onChanged: (m) {
                HapticFeedback.selectionClick();
                ref.read(themeModeProvider.notifier).set(m);
              },
            ),
            const SizedBox(height: 28),
            const _AppVersion(),
          ],
        ),
      ),
    );
  }
}

/// "Kese · v3.0.0 (3)"; sürüm pubspec.yaml'dan gelir. Okunamazsa yalnızca ad
/// gösterilir.
class _AppVersion extends StatefulWidget {
  const _AppVersion();

  @override
  State<_AppVersion> createState() => _AppVersionState();
}

class _AppVersionState extends State<_AppVersion> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Text(
          info == null
              ? 'Kese'
              : 'Kese · v${info.version} (${info.buildNumber})',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.muted, fontSize: 12),
        );
      },
    );
  }
}
