import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/game_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../themes/game_theme.dart';
import '../../../themes/theme_providers.dart';
import '../../../themes/theme_registry.dart';

/// YALNIZCA GELİŞTİRİCİ: zemin çubuğunun sağında küçük tema seçici (M3a).
/// Gerçek seçici M4'te Ayarlar ekranında olacak. Oyun ekranı bunu yalnızca
/// `kDebugToolsEnabled` iken (debug ve profile) ekler. Pencerenin altında
/// "Yüksek HP tahtası" seçeneği vardır.
class DebugThemePicker extends ConsumerWidget {
  /// "Yüksek HP tahtası" seçilince (pencere kapandıktan sonra) çağrılır.
  final VoidCallback onHighHpBoard;

  const DebugThemePicker({super.key, required this.onHighHpBoard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(selectedThemeProvider).palette;
    return IconButton(
      key: const Key('debugThemePicker'),
      padding: EdgeInsets.zero,
      iconSize: kDebugPickerSize * 2 / 3,
      color: palette.textSecondary,
      icon: const Icon(Icons.palette_outlined),
      tooltip: AppLocalizations.of(context).themePickerTitle,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => _ThemeDialog(onHighHpBoard: onHighHpBoard),
      ),
    );
  }
}

class _ThemeDialog extends ConsumerWidget {
  final VoidCallback onHighHpBoard;

  const _ThemeDialog({required this.onHighHpBoard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedThemeProvider);
    return SimpleDialog(
      title: Text(l10n.themePickerTitle),
      children: [
        for (final GameTheme theme in ThemeRegistry.all)
          SimpleDialogOption(
            key: Key('theme_${theme.id}'),
            onPressed: () {
              ref.read(selectedThemeProvider.notifier).select(theme);
              Navigator.of(context).pop();
            },
            child: Row(
              children: [
                Icon(
                  theme.id == selected.id ? Icons.check : Icons.circle_outlined,
                  color: theme.palette.accent,
                ),
                const SizedBox(width: kOverlayGap),
                Text(theme.displayName(l10n)),
                if (theme.isPlaceholder) ...[
                  const SizedBox(width: kOverlayGap),
                  Text(
                    l10n.themePlaceholderTag,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        const Divider(),
        SimpleDialogOption(
          key: const Key('debugHighHpBoard'),
          onPressed: () {
            Navigator.of(context).pop();
            onHighHpBoard();
          },
          child: Text(l10n.debugHighHpBoard),
        ),
      ],
    );
  }
}
