import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/asset_type.dart';
import '../../data/models/quote.dart';
import '../../state/providers.dart';
import '../../widgets/brand_ring.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import '../../widgets/quote_tile.dart';

/// Verilen türdeki varlıklar arasından aranabilir seçim yaptırır.
Future<Quote?> showAssetPicker(BuildContext context, AssetType type) {
  return showModalBottomSheet<Quote>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _AssetPicker(type: type),
    ),
  );
}

class _AssetPicker extends ConsumerStatefulWidget {
  const _AssetPicker({required this.type});

  final AssetType type;

  @override
  ConsumerState<_AssetPicker> createState() => _AssetPickerState();
}

class _AssetPickerState extends ConsumerState<_AssetPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('${widget.type.label} seç', style: context.text.titleLarge),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SearchField(onChanged: (q) => setState(() => _query = q)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: market.when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            data: (snapshot) {
              final quotes = filterQuotes(snapshot.of(widget.type), _query);
              if (quotes.isEmpty) {
                return const MessageView(
                  icon: Icons.search_off_rounded,
                  title: 'Sonuç bulunamadı',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: quotes.length,
                itemBuilder: (context, i) => QuoteTile(
                  quote: quotes[i],
                  onTap: () => Navigator.pop(context, quotes[i]),
                ),
              );
            },
            loading: () => const Center(child: BrandRing.loader()),
            error: (_, __) => MessageView(
              icon: Icons.cloud_off_rounded,
              title: 'Fiyatlar yüklenemedi',
              message: 'İnternet bağlantınızı kontrol edin.',
              actionLabel: 'Tekrar dene',
              onAction: () => ref.invalidate(marketProvider),
            ),
          ),
        ),
      ],
    );
  }
}
