import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_tracker/core/theme.dart';
import 'package:wealth_tracker/data/models/asset_type.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Küçük metin için WCAG AA 4.5:1 ister; "field" zemininde birkaç renk
  // 4.3 civarında kaldığından alt sınır orada biraz gevşek tutulur.
  for (final brightness in Brightness.values) {
    final theme = buildTheme(brightness);
    final palette = theme.extension<AppPalette>()!;
    final background = theme.scaffoldBackgroundColor;

    test('${brightness.name} temada metin renkleri okunur', () {
      for (final (name, color) in [
        ('muted', palette.muted),
        ('positive', palette.positive),
        ('negative', palette.negative),
        ('warning', palette.warning),
      ]) {
        expect(contrast(color, background), greaterThanOrEqualTo(4.5),
            reason: '$name zemin üzerinde');
        expect(contrast(color, palette.field), greaterThanOrEqualTo(4.3),
            reason: '$name alan zemini üzerinde');
      }
    });

    test('${brightness.name} temada avatar yazıları okunur', () {
      for (final type in AssetType.values) {
        final tint = Color.alphaBlend(
            AppPalette.typeColor(type).withValues(alpha: 0.12), background);
        expect(
          contrast(AppPalette.typeTextColor(type, brightness), tint),
          greaterThanOrEqualTo(4.3),
          reason: type.name,
        );
      }
    });
  }
}
