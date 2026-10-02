import 'package:flutter/material.dart';

import '../data/models/asset_type.dart';

/// Material renk şemasının dışında kalan uygulama renkleri.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.muted,
    required this.field,
    required this.border,
    required this.positive,
    required this.negative,
    required this.warning,
  });

  // Açık temada metin olarak kullanılan renkler zemin üzerinde en az ~4.5:1
  // kontrast verir (WCAG AA, küçük metin).
  static const light = AppPalette(
    muted: Color(0xFF6B6B70),
    field: Color(0xFFF0F0EE),
    border: Color(0xFFE8E8E5),
    positive: Color(0xFF0A7D4F),
    negative: Color(0xFFD13438),
    warning: Color(0xFF946200),
  );

  static const dark = AppPalette(
    muted: Color(0xFF94949A),
    field: Color(0xFF1C1C1F),
    border: Color(0xFF262629),
    positive: Color(0xFF3DD68C),
    negative: Color(0xFFFF6369),
    warning: Color(0xFFF5B942),
  );

  /// İkincil metin.
  final Color muted;

  /// Girdi alanı ve seçili olmayan kontrol zemini.
  final Color field;
  final Color border;
  final Color positive;
  final Color negative;

  /// Eskimiş veri gibi hata olmayan uyarılar.
  final Color warning;

  Color change(double? value) {
    if (value == null || value.abs() < 0.005) return muted;
    return value > 0 ? positive : negative;
  }

  /// Çubuk, nokta ve zemin tonu için varlık rengi (ikondaki halkayla aynı).
  static Color typeColor(AssetType type) => switch (type) {
        AssetType.gold => const Color(0xFFD9A21B),
        AssetType.currency => const Color(0xFF3E7BFA),
        AssetType.crypto => const Color(0xFF8B5CF6),
        AssetType.cash => const Color(0xFF14B8A6),
      };

  /// Varlık rengiyle yazılan metinler için. Parlak tonlar açık zeminde
  /// okunmadığından (altın 1.96:1) açık temada aynı rengin koyusu kullanılır.
  static Color typeTextColor(AssetType type, Brightness brightness) {
    if (brightness == Brightness.dark) {
      // Mor, koyu zeminde 4.2:1'de kalıyor; biraz açılır.
      return type == AssetType.crypto
          ? const Color(0xFFA78BFA)
          : typeColor(type);
    }
    return switch (type) {
      AssetType.gold => const Color(0xFF8A6100),
      AssetType.currency => const Color(0xFF2B62D9),
      AssetType.crypto => const Color(0xFF7442E0),
      AssetType.cash => const Color(0xFF0B7A6E),
    };
  }

  @override
  AppPalette copyWith({
    Color? muted,
    Color? field,
    Color? border,
    Color? positive,
    Color? negative,
    Color? warning,
  }) =>
      AppPalette(
        muted: muted ?? this.muted,
        field: field ?? this.field,
        border: border ?? this.border,
        positive: positive ?? this.positive,
        negative: negative ?? this.negative,
        warning: warning ?? this.warning,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      muted: Color.lerp(muted, other.muted, t)!,
      field: Color.lerp(field, other.field, t)!,
      border: Color.lerp(border, other.border, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension ThemeX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Rakamların alt alta hizalanması için sabit genişlikli rakamlar.
const tabular = [FontFeature.tabularFigures()];

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? AppPalette.dark : AppPalette.light;
  final background = isDark ? const Color(0xFF0B0B0C) : const Color(0xFFF7F7F5);
  final surface = isDark ? const Color(0xFF141416) : Colors.white;
  final foreground = isDark ? const Color(0xFFF3F3F3) : const Color(0xFF111113);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: foreground,
    onPrimary: background,
    secondary: foreground,
    onSecondary: background,
    error: palette.negative,
    onError: Colors.white,
    surface: background,
    onSurface: foreground,
    onSurfaceVariant: palette.muted,
    surfaceContainerLowest: surface,
    surfaceContainerLow: surface,
    surfaceContainer: surface,
    surfaceContainerHigh: surface,
    surfaceContainerHighest: palette.field,
    outline: palette.border,
    outlineVariant: palette.border,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
  );

  final text = base.textTheme
      .copyWith(
        headlineSmall: base.textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.6),
        titleLarge: base.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.4),
        titleMedium: base.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(letterSpacing: -0.1),
        labelLarge: base.textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      )
      .apply(bodyColor: foreground, displayColor: foreground);

  final radius = BorderRadius.circular(14);

  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: text,
    extensions: [palette],
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: palette.field,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? foreground
              : palette.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? foreground
              : palette.muted,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.field,
      hintStyle: TextStyle(color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder:
          OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: foreground, width: 1.2),
      ),
      prefixIconColor: palette.muted,
      suffixIconColor: palette.muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 54),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
        disabledBackgroundColor: palette.field,
        disabledForegroundColor: palette.muted,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: palette.border,
      dragHandleSize: const Size(36, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: foreground,
      contentTextStyle: TextStyle(
          color: background, fontFamily: 'Inter', fontWeight: FontWeight.w500),
      actionTextColor: background,
      shape: RoundedRectangleBorder(borderRadius: radius),
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(color: palette.border, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: foreground,
      linearTrackColor: palette.field,
      refreshBackgroundColor: surface,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
    ),
  );
}
