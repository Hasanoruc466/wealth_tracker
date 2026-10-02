import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models/asset_type.dart';
import '../../data/models/quote.dart';
import '../../state/providers.dart';
import '../../widgets/asset_avatar.dart';
import '../../widgets/brand_ring.dart';
import '../../widgets/common.dart';
import '../../widgets/sparkline.dart';
import '../../widgets/view_options.dart';
import '../holding/holding_sheet.dart';

class PortfolioPage extends ConsumerStatefulWidget {
  const PortfolioPage({super.key});

  @override
  ConsumerState<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends ConsumerState<PortfolioPage> {
  /// Dağılımdan seçilen tür; `null` ise tüm varlıklar listelenir.
  AssetType? _filter;

  void _toggleFilter(AssetType type) {
    HapticFeedback.selectionClick();
    setState(() => _filter = _filter == type ? null : type);
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final snapshot = market.valueOrNull;
    final summary = ref.watch(portfolioSummaryProvider);
    final hidden = ref.watch(hideBalancesProvider);
    final metric = ref.watch(rowMetricProvider);
    final palette = context.palette;

    // Filtrelenen tür portföyden tamamen silindiyse filtre düşer.
    final filter = summary.allocation.containsKey(_filter) ? _filter : null;
    final items =
        filter == null
            ? summary.items
            : summary.items.where((i) => i.holding.type == filter).toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: ref.read(marketProvider.notifier).refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'Portföy',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SyncStatus(
                      updatedAt: snapshot?.updatedAt,
                      isStale: snapshot?.isStale ?? false,
                    ),
                    const SizedBox(width: 4),
                    const ViewOptionsButton(),
                  ],
                ),
              ),
            ),
            if (summary.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: MessageView(
                  icon: Icons.account_balance_wallet_outlined,
                  illustration: Column(
                    children: [
                      const BrandRing(size: 72),
                      const SizedBox(height: 14),
                      Text(
                        'KESE',
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                  // Uygulamanın sloganı; ilk açılışta görülen ekran.
                  title: 'Tüm varlıkların, tek rakam.',
                  prominent: true,
                  message:
                      'Altın, döviz, kripto ve nakdini ekle; hepsini güncel '
                      'fiyatlarla tek bir toplamda gör.',
                  actionLabel: 'Varlık ekle',
                  onAction: () => showHoldingSheet(context),
                ),
              )
            else if (snapshot == null && market.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: MessageView(
                  icon: Icons.cloud_off_rounded,
                  title: 'Fiyatlar alınamadı',
                  message: 'İnternet bağlantını kontrol edip tekrar dene.',
                  actionLabel: 'Tekrar dene',
                  onAction: () => ref.invalidate(marketProvider),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: _SummaryHeader(
                  summary: summary,
                  loading: snapshot == null,
                  hidden: hidden,
                  filter: filter,
                  onFilter: _toggleFilter,
                ),
              ),
              SliverToBoxAdapter(
                child: _ListHeader(
                  filter: filter,
                  count: items.length,
                  metric: metric,
                  onClearFilter: () => setState(() => _filter = null),
                ),
              ),
              if (metric == RowMetric.profit &&
                  summary.hasMissingCost &&
                  !ref.watch(costHintSeenProvider))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Alış fiyatı girilmemiş varlıklarda kâr/zarar '
                            'gösterilmez. Eklemek için varlığa dokun.',
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () =>
                                  ref
                                      .read(costHintSeenProvider.notifier)
                                      .markSeen(),
                          tooltip: 'Anladım',
                          iconSize: 16,
                          color: palette.muted,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverList.builder(
                itemCount: items.length,
                itemBuilder:
                    (context, i) => _HoldingRow(
                      item: items[i],
                      loading: snapshot == null,
                      hidden: hidden,
                      metric: metric,
                    ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends ConsumerWidget {
  const _ListHeader({
    required this.filter,
    required this.count,
    required this.metric,
    required this.onClearFilter,
  });

  final AssetType? filter;
  final int count;
  final RowMetric metric;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final pillStyle = TextButton.styleFrom(
      backgroundColor: palette.field,
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
      shape: const StadiumBorder(),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 4),
      child: Row(
        children: [
          Text(filter?.label ?? 'Varlıklar', style: context.text.titleMedium),
          const SizedBox(width: 8),
          Text('$count', style: TextStyle(color: palette.muted)),
          if (filter != null)
            IconButton(
              onPressed: onClearFilter,
              tooltip: 'Filtreyi kaldır',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              color: palette.muted,
              icon: const Icon(Icons.close_rounded),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(rowMetricProvider.notifier).toggle();
            },
            icon: const Icon(Icons.swap_vert_rounded, size: 18),
            label: Text(metric.label),
            style: pillStyle.copyWith(
              foregroundColor: WidgetStatePropertyAll(palette.muted),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => showHoldingSheet(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ekle'),
            style: pillStyle,
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends ConsumerWidget {
  const _SummaryHeader({
    required this.summary,
    required this.loading,
    required this.hidden,
    required this.filter,
    required this.onFilter,
  });

  final PortfolioSummary summary;
  final bool loading;
  final bool hidden;
  final AssetType? filter;
  final ValueChanged<AssetType> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final history = ref.watch(historyProvider);
    final worth = ref.watch(netWorthProvider);
    final profit = summary.profit;
    // En fazla son 30 gün.
    final recent =
        history.length > 30 ? history.sublist(history.length - 30) : history;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                worth.hasDebts ? 'Net değer' : 'Toplam değer',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hidden) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.visibility_off_outlined,
                  size: 14,
                  color: palette.muted,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (loading) ...[
            const _Placeholder(width: 220, height: 44),
            const SizedBox(height: 12),
            const _Placeholder(width: 140, height: 16),
          ] else ...[
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(hideBalancesProvider.notifier).toggle();
              },
              child:
                  hidden
                      ? const _BigText(Fmt.hidden, '')
                      : TweenAnimationBuilder<double>(
                        tween: Tween(end: worth.total),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, _) => _BigMoney(value),
                      ),
            ),
            const SizedBox(height: 10),
            if (worth.hasDebts) ...[
              const SizedBox(height: 2),
              _NetBreakdown(worth: worth, hidden: hidden),
              const SizedBox(height: 10),
            ],
            _ChangeLine(
              percent: worth.dailyChangePercent,
              amount: worth.dailyChange,
              hidden: hidden,
              label: 'bugün',
            ),
            if (profit != null) ...[
              const SizedBox(height: 6),
              _ChangeLine(
                percent: summary.profitPercent ?? 0,
                amount: profit,
                hidden: hidden,
                label: 'toplam kâr/zarar',
              ),
            ],
            const SizedBox(height: 18),
            if (recent.length >= 2) ...[
              Sparkline(
                values: [for (final p in recent) p.total],
                color:
                    recent.last.total >= recent.first.total
                        ? palette.positive
                        : palette.negative,
              ),
              const SizedBox(height: 6),
              Text(
                'Son ${recent.length} günde ${worth.hasDebts ? 'net' : 'toplam'} değer',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ] else
              Row(
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 16,
                    color: palette.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Değer grafiğin yarından itibaren burada görünecek.',
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: card,
          ),
          const SizedBox(height: 20),
          _Allocation(
            summary: summary,
            hidden: hidden,
            selected: filter,
            onSelect: onFilter,
          ),
        ],
      ),
    );
  }
}

/// "Varlıklar ₺X  +Alacak ₺Y  −Borç ₺Z"; dokununca Borçlar sekmesine gider.
class _NetBreakdown extends ConsumerWidget {
  const _NetBreakdown({required this.worth, required this.hidden});

  final NetWorth worth;
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    String money(double v) => hidden ? Fmt.hidden : Fmt.money(v);
    final muted = TextStyle(color: palette.muted);
    const strong = TextStyle(fontWeight: FontWeight.w500);

    return InkWell(
      onTap: () => ref.read(homeTabProvider.notifier).state = 1,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Varlıklar ', style: muted),
              TextSpan(text: money(worth.assets.total), style: strong),
              if (worth.debts.lent > 0) ...[
                TextSpan(text: '  + Alacak ', style: muted),
                TextSpan(text: money(worth.debts.lent), style: strong),
              ],
              if (worth.debts.borrowed > 0) ...[
                TextSpan(text: '  − Borç ', style: muted),
                TextSpan(text: money(worth.debts.borrowed), style: strong),
              ],
            ],
          ),
          style: const TextStyle(fontSize: 12, fontFeatures: tabular),
        ),
      ),
    );
  }
}

class _ChangeLine extends StatelessWidget {
  const _ChangeLine({
    required this.percent,
    required this.amount,
    required this.hidden,
    required this.label,
  });

  final double percent;
  final double amount;
  final bool hidden;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChangeText(
          percent,
          amount: amount,
          hideAmount: hidden,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: context.palette.muted, fontSize: 14),
        ),
      ],
    );
  }
}

/// Kuruşları daha soluk gösteren büyük tutar.
class _BigMoney extends StatelessWidget {
  const _BigMoney(this.value);

  final double value;

  @override
  Widget build(BuildContext context) {
    final formatted = Fmt.money(value);
    final split = formatted.lastIndexOf(',');
    return split == -1
        ? _BigText(formatted, '')
        : _BigText(formatted.substring(0, split), formatted.substring(split));
  }
}

class _BigText extends StatelessWidget {
  const _BigText(this.whole, this.fraction);

  final String whole;
  final String fraction;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 42,
      height: 1.1,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.6,
      fontFeatures: tabular,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: whole, style: style),
            TextSpan(
              text: fraction,
              style: style.copyWith(color: context.palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Türlere göre dağılım çubuğu ve dokunulabilir 2×2 lejant.
class _Allocation extends StatelessWidget {
  const _Allocation({
    required this.summary,
    required this.hidden,
    required this.selected,
    required this.onSelect,
  });

  final PortfolioSummary summary;
  final bool hidden;
  final AssetType? selected;
  final ValueChanged<AssetType> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = summary.total;
    if (total <= 0) return const SizedBox.shrink();
    final entries =
        summary.allocation.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    bool dimmed(AssetType type) => selected != null && selected != type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final (i, entry) in entries.indexed)
                Expanded(
                  flex: max(1, (entry.value / total * 1000).round()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: i == entries.length - 1 ? 0 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.typeColor(
                        entry.key,
                      ).withValues(alpha: dimmed(entry.key) ? 0.25 : 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tek sıra, yatay kayar; dört tür olsa da başlık alanı kısa kalır.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final (i, entry) in entries.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                ConstrainedBox(
                  // İçeriğe göre genişler; büyük yazı boyutunda taşmaz.
                  constraints: const BoxConstraints(minWidth: 140),
                  child: _AllocationTile(
                    type: entry.key,
                    share: entry.value / total * 100,
                    value: entry.value,
                    hidden: hidden,
                    selected: selected == entry.key,
                    dimmed: dimmed(entry.key),
                    onTap: () => onSelect(entry.key),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AllocationTile extends StatelessWidget {
  const _AllocationTile({
    required this.type,
    required this.share,
    required this.value,
    required this.hidden,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final AssetType type;
  final double share;
  final double value;
  final bool hidden;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = AppPalette.typeColor(type);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : palette.field,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: dimmed ? 0.45 : 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Spacer(),
                        Text(
                          Fmt.share(share),
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.muted,
                            fontWeight: FontWeight.w500,
                            fontFeatures: tabular,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hidden ? Fmt.hidden : Fmt.money(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.muted,
                        fontFeatures: tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldingRow extends ConsumerWidget {
  const _HoldingRow({
    required this.item,
    required this.loading,
    required this.hidden,
    required this.metric,
  });

  final HoldingValue item;
  final bool loading;
  final bool hidden;
  final RowMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final holding = item.holding;
    final quote = item.quote;
    final isCash = holding.type == AssetType.cash;
    final amount = hidden ? Fmt.hiddenAmount : Fmt.amount(holding.amount);

    final subtitle = switch (quote) {
      _ when loading => amount,
      null => '$amount · fiyat bulunamadı',
      _ when isCash => 'Nakit',
      final Quote q => '$amount × ${Fmt.price(q.price)}',
    };

    final Widget change = switch (metric) {
      _ when isCash => const SizedBox.shrink(),
      RowMetric.daily => ChangeText(quote?.changePercent),
      RowMetric.profit =>
        item.profitPercent == null
            ? Text('—', style: TextStyle(color: palette.muted, fontSize: 13))
            : ChangeText(item.profitPercent),
    };

    return Dismissible(
      key: ValueKey(holding.key),
      direction: DismissDirection.endToStart,
      background: Container(
        color: palette.negative.withValues(alpha: 0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline_rounded, color: palette.negative),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        removeHoldingWithUndo(
          notifier: ref.read(portfolioProvider.notifier),
          messenger: ScaffoldMessenger.of(context),
          key: holding.key,
          name: item.name,
        );
      },
      child: InkWell(
        onTap: () => showHoldingSheet(context, holding: holding),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              AssetAvatar(type: holding.type, code: holding.code),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            quote == null && !loading
                                ? palette.negative
                                : palette.muted,
                        fontFeatures: tabular,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (loading)
                const _Placeholder(width: 72, height: 14)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      quote == null
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
                    const SizedBox(height: 2),
                    change,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.field,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
