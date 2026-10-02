import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/models/asset_type.dart';
import '../data/models/quote.dart';
import 'asset_avatar.dart';
import 'common.dart';

/// Piyasa listesindeki bir satır: ad, kod, alış fiyatı ve günlük değişim.
class QuoteTile extends StatelessWidget {
  const QuoteTile({
    super.key,
    required this.quote,
    this.onTap,
    this.trailing,
    this.held,
  });

  final Quote quote;
  final VoidCallback? onTap;

  /// Kullanıcının bu varlıktan sahip olduğu miktar ("6 adet"); gizli bakiye
  /// modunda boş metin verilir, `null` ise sahip değildir.
  final String? held;

  /// Verilirse fiyat sütununun yerine geçer.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subtitle = switch (quote.type) {
      _ when quote.sell != quote.buy => 'Satış ${Fmt.price(quote.sell)}',
      AssetType.gold => '',
      // "XRP / XRP" gibi tekrarları gösterme.
      _ when quote.name.toUpperCase() == quote.code.toUpperCase() => '',
      _ => quote.code,
    };
    final held = this.held;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            AssetAvatar(type: quote.type, code: quote.code),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty || held != null) ...[
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: subtitle),
                        if (held != null) ...[
                          if (subtitle.isNotEmpty) const TextSpan(text: '  ·  '),
                          TextSpan(
                            text: held.isEmpty ? 'Sende var' : 'Sende $held',
                            style: TextStyle(
                              color: context.colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.muted,
                        fontFeatures: tabular,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Fmt.price(quote.price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFeatures: tabular,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ChangeText(quote.changePercent),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
