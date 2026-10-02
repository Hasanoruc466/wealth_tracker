import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models/asset_type.dart';
import '../../data/models/debt.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/view_options.dart';
import 'debt_sheet.dart';

class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(debtSummaryProvider);
    final hidden = ref.watch(hideBalancesProvider);
    final palette = context.palette;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: ref.read(marketProvider.notifier).refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: PageHeader(title: 'Borçlar', trailing: ViewOptionsButton()),
            ),
            if (summary.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: MessageView(
                  icon: Icons.handshake_outlined,
                  title: 'Borç kaydı yok',
                  message:
                      'Verdiğin ya da aldığın borçları ekle; altın ya da döviz '
                      'cinsinden olsalar bile güncel değerleriyle net varlığına yansısın.',
                  actionLabel: 'Kayıt ekle',
                  onAction: () => showDebtSheet(context),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TotalCard(
                          label: 'Alacağım',
                          icon: Icons.south_west_rounded,
                          value: summary.lent,
                          hidden: hidden,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TotalCard(
                          label: 'Borcum',
                          icon: Icons.north_east_rounded,
                          value: summary.borrowed,
                          hidden: hidden,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: 'Net  ',
                          style: TextStyle(color: palette.muted)),
                      TextSpan(
                        text: hidden
                            ? Fmt.hidden
                            : Fmt.signedMoney(summary.lent - summary.borrowed),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ]),
                    style: const TextStyle(fontSize: 14, fontFeatures: tabular),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                  child: Row(
                    children: [
                      Text('Kayıtlar', style: context.text.titleMedium),
                      const SizedBox(width: 8),
                      Text('${summary.items.length}',
                          style: TextStyle(color: palette.muted)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => showDebtSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Ekle'),
                        style: TextButton.styleFrom(
                          backgroundColor: palette.field,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
                          shape: const StadiumBorder(),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final direction in DebtDirection.values)
                if (summary.of(direction).isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Text(
                        direction.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.muted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  SliverList.list(children: [
                    for (final item in summary.of(direction))
                      _DebtRow(item: item, hidden: hidden),
                  ]),
                ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Toplam alacak ya da borç. Kâr/zarar renkleriyle karışmasın diye nötrdür;
/// yön, okla belirtilir (↙ bana gelecek, ↗ benden çıkacak).
class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.hidden,
  });

  final String label;
  final IconData icon;
  final double value;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final empty = value <= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: palette.field,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: palette.muted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: palette.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hidden ? Fmt.hidden : Fmt.money(value),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                fontFeatures: tabular,
                color: empty ? palette.muted : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtRow extends ConsumerWidget {
  const _DebtRow({required this.item, required this.hidden});

  final DebtValue item;
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final debt = item.debt;
    final isCash = debt.type == AssetType.cash;
    final amount = hidden ? Fmt.hiddenAmount : Fmt.amount(debt.amount);
    final what = isCash
        ? 'Nakit'
        : '${item.assetName} · $amount ${unitLabel(debt.type, debt.code)}';
    final overdue = debt.isOverdue(DateTime.now());
    final due = debt.dueDate;

    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: palette.field,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: palette.muted),
            const SizedBox(width: 8),
            Text('Kapat', style: TextStyle(color: palette.muted)),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        removeDebtWithUndo(
          notifier: ref.read(debtsProvider.notifier),
          messenger: ScaffoldMessenger.of(context),
          id: debt.id,
        );
      },
      child: InkWell(
        onTap: () => showDebtSheet(context, debt: debt),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.field,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(debt.person),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        debt.isLent
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        size: 13,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.person,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: what),
                        if (due != null)
                          TextSpan(
                            text: overdue
                                ? '  ·  Vadesi geçti'
                                : '  ·  ${Fmt.date(due)}',
                            style: overdue
                                ? TextStyle(
                                    color: palette.negative,
                                    fontWeight: FontWeight.w600,
                                  )
                                : null,
                          ),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.muted,
                        fontFeatures: tabular,
                      ),
                    ),
                    if (debt.note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        debt.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.quote == null
                    ? '—'
                    : hidden
                        ? Fmt.hidden
                        : Fmt.money(item.value),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFeatures: tabular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Ayşe Yılmaz" → "AY", "mehmet" → "M".
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts
        .take(2)
        .map((p) => p.characters.first)
        .join()
        // Türkçe büyük harf: i → İ, ı → I.
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .toUpperCase();
  }
}
