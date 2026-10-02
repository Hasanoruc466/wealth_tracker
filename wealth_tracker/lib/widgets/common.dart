import 'dart:async';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';

/// Yön oku ve renkle gösterilen değişim: ▲ ₺1.234,56  %1,23.
///
/// Renk körlüğü olanlar için yön yalnızca renkle değil okla da belirtilir.
/// [percent] yoksa hiçbir şey çizmez; [amount] verilirse yüzdenin önüne
/// eklenir ve [hideAmount] ile gizlenebilir.
class ChangeText extends StatelessWidget {
  const ChangeText(
    this.percent, {
    super.key,
    this.amount,
    this.hideAmount = false,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w500,
  });

  final double? percent;
  final double? amount;
  final bool hideAmount;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final value = percent;
    if (value == null) return const SizedBox.shrink();
    final color = context.palette.change(value);
    final direction = value.abs() < 0.005 ? 0 : value.sign.toInt();
    final money = amount == null
        ? null
        : hideAmount
            ? Fmt.hidden
            : Fmt.money(amount!.abs());
    final text = [if (money != null) money, Fmt.percentAbs(value)].join('  ');
    final spoken = [
      if (amount != null) hideAmount ? 'gizli tutar' : Fmt.signedMoney(amount!),
      Fmt.percent(value),
    ].join(', ');

    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (direction != 0) ...[
            CustomPaint(
              size: Size.square(fontSize * 0.6),
              painter: _TrianglePainter(color: color, up: direction > 0),
            ),
            SizedBox(width: fontSize * 0.3),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontFeatures: tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color, required this.up});

  final Color color;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height * 0.8;
    final top = (size.height - h) / 2;
    final path = up
        ? (Path()
          ..moveTo(w / 2, top)
          ..lineTo(w, top + h)
          ..lineTo(0, top + h))
        : (Path()
          ..moveTo(0, top)
          ..lineTo(w, top)
          ..lineTo(w / 2, top + h));
    canvas.drawPath(
      path..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.color != color || old.up != up;
}

/// Fiyatların ne kadar güncel olduğu: "Güncel · 22:42".
///
/// Bazı kaynaklar yanıt vermediyse ya da veri [staleAfter] süresinden eskiyse
/// uyarı rengiyle "Eski" olarak gösterilir.
class SyncStatus extends StatefulWidget {
  const SyncStatus({super.key, required this.updatedAt, required this.isStale});

  final DateTime? updatedAt;
  final bool isStale;

  /// Yenileme aralığının (1 dk) birkaç katı.
  static const staleAfter = Duration(minutes: 10);

  @override
  State<SyncStatus> createState() => _SyncStatusState();
}

class _SyncStatusState extends State<SyncStatus> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    // Uygulama çevrimdışıyken de etiketin eskidiği görülsün.
    _ticker =
        Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = widget.updatedAt;
    if (time == null) return const SizedBox.shrink();
    final palette = context.palette;
    final tooOld = DateTime.now().difference(time) > SyncStatus.staleAfter;
    final stale = widget.isStale || tooOld;
    final color = stale ? palette.warning : palette.positive;

    return Tooltip(
      message: widget.isStale
          ? 'Bazı fiyatlar güncellenemedi; son bilinen değerler gösteriliyor.'
          : tooOld
              ? 'Fiyatlar bir süredir güncellenemedi. Yenilemek için aşağı çek.'
              : 'Fiyatlar her dakika yenilenir.',
      triggerMode: TooltipTriggerMode.tap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '${stale ? 'Eski' : 'Güncel'} · ${Fmt.time(time)}',
            style: TextStyle(
              fontSize: 12,
              color: stale ? color : palette.muted,
              fontWeight: stale ? FontWeight.w600 : FontWeight.w400,
              fontFeatures: tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ortalanmış simge, başlık, açıklama ve isteğe bağlı eylem.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.illustration,
    this.prominent = false,
  });

  final IconData icon;

  /// Verilirse simge kutusunun yerine gösterilir.
  final Widget? illustration;

  /// Karşılama ekranları için daha büyük başlık.
  final bool prominent;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: palette.field,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: palette.muted),
                ),
            const SizedBox(height: 20),
            Text(title,
                style: prominent
                    ? context.text.headlineSmall
                    : context.text.titleMedium,
                textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, height: 1.4),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sayfa üstündeki başlık satırı.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Text(title, style: context.text.titleLarge),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
