import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/models/asset_type.dart';

/// Türünün rengiyle hafifçe boyanmış, kısa kod gösteren kare simge.
class AssetAvatar extends StatelessWidget {
  const AssetAvatar({
    super.key,
    required this.type,
    required this.code,
    this.size = 42,
  });

  final AssetType type;
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppPalette.typeColor(type);
    final textColor =
        AppPalette.typeTextColor(type, Theme.of(context).brightness);
    final label = shortLabel(type, code);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          // Kodlar (BTC, USDT, DOGE) uzunluğundan bağımsız aynı boyda; yalnızca
          // element simgeleri (Au, Ag) ve ₺ biraz daha büyük.
          fontSize: size * (label.length <= 2 ? 0.32 : 0.25),
          letterSpacing: label.length > 3 ? -0.6 : -0.3,
        ),
      ),
    );
  }
}
