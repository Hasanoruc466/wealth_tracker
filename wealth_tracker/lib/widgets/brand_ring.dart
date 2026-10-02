import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/asset_type.dart';

/// Uygulama ikonundaki dört renkli portföy halkası.
///
/// [spinning] verilirse yükleme göstergesi olarak döner.
class BrandRing extends StatefulWidget {
  const BrandRing({super.key, this.size = 56, this.spinning = false});

  /// Yükleme göstergesi olarak kullanılan küçük, dönen halka.
  const BrandRing.loader({super.key, this.size = 28}) : spinning = true;

  final double size;
  final bool spinning;

  @override
  State<BrandRing> createState() => _BrandRingState();
}

class _BrandRingState extends State<BrandRing>
    with SingleTickerProviderStateMixin {
  /// Yalnızca dönen halkada oluşturulur.
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.spinning) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = CustomPaint(
      size: Size.square(widget.size),
      painter: const _RingPainter(),
    );
    final controller = _controller;
    if (controller == null) return ring;
    return Semantics(
      label: 'Yükleniyor',
      child: RotationTransition(turns: controller, child: ring),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter();

  // tool/generate_icon.py ile aynı oranlar.
  static const _segments = [
    (AssetType.gold, 0.36),
    (AssetType.currency, 0.26),
    (AssetType.crypto, 0.20),
    (AssetType.cash, 0.18),
  ];
  static const _thickness = 0.18; // çapa oranı
  static const _gap = 0.028; // çapa oranı

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.shortestSide;
    final stroke = d * _thickness;
    final r = (d - stroke) / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    // Boşluk orta yarıçapta ölçülür.
    final gapAngle = d * _gap / r;
    var start = -pi / 2;
    for (final (type, share) in _segments) {
      final sweep = 2 * pi * share;
      canvas.drawArc(
        rect,
        start + gapAngle / 2,
        sweep - gapAngle,
        false,
        Paint()
          ..color = AppPalette.typeColor(type)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => false;
}
