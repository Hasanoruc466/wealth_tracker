import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models/asset_type.dart';
import '../../state/providers.dart';
import '../../widgets/brand_ring.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import '../../widgets/quote_tile.dart';
import '../../widgets/view_options.dart';
import '../holding/holding_sheet.dart';

class MarketsPage extends ConsumerStatefulWidget {
  const MarketsPage({super.key});

  @override
  ConsumerState<MarketsPage> createState() => _MarketsPageState();
}

class _MarketsPageState extends ConsumerState<MarketsPage> {
  AssetType _type = AssetType.gold;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final snapshot = market.valueOrNull;
    final hidden = ref.watch(hideBalancesProvider);
    final holdings = {
      for (final h in ref.watch(portfolioProvider)) h.key: h,
    };

    final Widget body;
    if (snapshot == null) {
      body = market.hasError
          ? MessageView(
              icon: Icons.cloud_off_rounded,
              title: 'Fiyatlar alınamadı',
              message: 'İnternet bağlantını kontrol edip tekrar dene.',
              actionLabel: 'Tekrar dene',
              onAction: () => ref.invalidate(marketProvider),
            )
          : const Center(child: BrandRing.loader());
    } else {
      final quotes = filterQuotes(snapshot.of(_type), _query);
      body = RefreshIndicator(
        onRefresh: ref.read(marketProvider.notifier).refresh,
        child: quotes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  MessageView(
                    icon: Icons.search_off_rounded,
                    title: 'Sonuç bulunamadı',
                  ),
                ],
              )
            : ListView.builder(
                // Sekme değişince liste en baştan başlasın.
                key: ValueKey(_type),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: quotes.length,
                itemBuilder: (context, i) {
                  final quote = quotes[i];
                  final holding = holdings[quote.key];
                  return QuoteTile(
                    quote: quote,
                    held: holding == null
                        ? null
                        : hidden
                            ? ''
                            : '${Fmt.amount(holding.amount)} ${unitLabel(quote.type, quote.code)}',
                    onTap: () => showHoldingSheet(context, initial: quote),
                  );
                },
              ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          PageHeader(
            title: 'Piyasalar',
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Segmented<AssetType>(
              values: AssetType.markets,
              value: _type,
              label: (t) => t.label,
              onChanged: (t) => setState(() => _type = t),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SearchField(
              hint: '${_type.label} ara',
              onChanged: (q) => setState(() => _query = q),
            ),
          ),
          const SizedBox(height: 8),
          if (snapshot != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.palette.muted,
                  letterSpacing: 0.2,
                ),
                child: const Row(
                  children: [
                    Text('VARLIK'),
                    Spacer(),
                    Text('ALIŞ · GÜNLÜK'),
                  ],
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
