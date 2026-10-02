import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models/asset_type.dart';
import '../../data/models/holding.dart';
import '../../data/models/quote.dart';
import '../../state/providers.dart';
import '../../widgets/asset_avatar.dart';
import '../../widgets/asset_field.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import 'asset_picker.dart';

/// [holding] verilirse düzenleme, verilmezse ekleme modunda açılır.
/// Ekleme modunda [initial] ile bir varlık önceden seçilebilir.
Future<void> showHoldingSheet(
  BuildContext context, {
  Holding? holding,
  Quote? initial,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => HoldingSheet(holding: holding, initial: initial),
  );
}

/// Silme işlemini "Geri al" seçeneği sunan bir bildirimle yapar.
void removeHoldingWithUndo({
  required PortfolioNotifier notifier,
  required ScaffoldMessengerState messenger,
  required String key,
  required String name,
}) {
  final removed = notifier.remove(key);
  if (removed == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$name silindi'),
      action: SnackBarAction(
        label: 'Geri al',
        onPressed: () => notifier.restore(removed),
      ),
    ));
}

class HoldingSheet extends ConsumerStatefulWidget {
  const HoldingSheet({super.key, this.holding, this.initial});

  final Holding? holding;
  final Quote? initial;

  @override
  ConsumerState<HoldingSheet> createState() => _HoldingSheetState();
}

class _HoldingSheetState extends ConsumerState<HoldingSheet> {
  late AssetType _type =
      widget.holding?.type ?? widget.initial?.type ?? AssetType.gold;
  late String? _code = widget.holding?.code ?? widget.initial?.code;
  late final _amount = TextEditingController(
    text: widget.holding == null ? '' : Fmt.amountInput(widget.holding!.amount),
  );
  late final _cost = TextEditingController(
    text: widget.holding?.avgCost == null
        ? ''
        : Fmt.amountInput(widget.holding!.avgCost!),
  );

  bool get _isEdit => widget.holding != null;

  @override
  void dispose() {
    _amount.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _selectType(AssetType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      // Tür değişince önceki seçim geçersizdir.
      _code = type == AssetType.cash ? Quote.cash.code : null;
    });
  }

  Future<void> _pickAsset() async {
    final quote = await showAssetPicker(context, _type);
    if (quote != null && mounted) setState(() => _code = quote.code);
  }

  void _submit(double amount, double? unitCost) {
    final notifier = ref.read(portfolioProvider.notifier);
    if (_isEdit) {
      notifier.edit(widget.holding!.key, amount, avgCost: unitCost);
    } else {
      notifier.add(_type, _code!, amount, unitCost: unitCost);
    }
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _delete(String name) {
    final notifier = ref.read(portfolioProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    removeHoldingWithUndo(
      notifier: notifier,
      messenger: messenger,
      key: widget.holding!.key,
      name: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final market = ref.watch(marketProvider).valueOrNull;
    final code = _code;
    final quote = code == null
        ? null
        : (_type == AssetType.cash ? Quote.cash : market?.find(_type, code));
    final name = code == null ? null : quote?.name ?? displayName(_type, code);

    final amount = Fmt.parseAmount(_amount.text);
    final canSubmit = code != null && amount != null && amount > 0;
    final existing = _isEdit || code == null
        ? null
        : ref
            .watch(portfolioProvider)
            .where((h) => h.type == _type && h.code == code)
            .firstOrNull;

    final tracksCost = _type != AssetType.cash;
    final enteredCost = tracksCost ? Fmt.parseAmount(_cost.text) : null;
    // Maliyeti bilinen bir varlığa fiyatsız ekleme yapılırsa ortalamanın
    // bozulmaması için güncel fiyattan alınmış sayılır.
    final unitCost = enteredCost ??
        (existing?.avgCost != null ? quote?.price : null);
    final unit = unitLabel(_type, code);
    final profit = canSubmit && quote != null && enteredCost != null
        ? amount * (quote.price - enteredCost)
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEdit ? 'Varlığı düzenle' : 'Varlık ekle',
              style: context.text.titleLarge),
          const SizedBox(height: 20),
          if (_isEdit)
            _SelectedAsset(type: _type, code: code!, name: name!, quote: quote)
          else ...[
            Segmented<AssetType>(
              values: AssetType.values,
              value: _type,
              label: (t) => t.label,
              onChanged: _selectType,
            ),
            if (_type != AssetType.cash) ...[
              const SizedBox(height: 12),
              AssetField(
                type: _type,
                code: code,
                name: name,
                onTap: _pickAsset,
              ),
            ],
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            autofocus: _isEdit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [Fmt.amountInputFormatter],
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: canSubmit ? (_) => _submit(amount, unitCost) : null,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFeatures: tabular,
            ),
            decoration: InputDecoration(
              hintText: 'Miktar',
              hintStyle: TextStyle(
                  color: palette.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w400),
              suffixText: unit,
              suffixStyle: TextStyle(color: palette.muted, fontSize: 14),
            ),
          ),
          if (tracksCost) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _cost,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [Fmt.amountInputFormatter],
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted:
                  canSubmit ? (_) => _submit(amount, unitCost) : null,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFeatures: tabular,
              ),
              decoration: InputDecoration(
                hintText: unit == null
                    ? 'Alış fiyatı (isteğe bağlı)'
                    : 'Alış fiyatı / $unit (isteğe bağlı)',
                hintStyle: TextStyle(
                    color: palette.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400),
                prefixText: '₺ ',
                prefixStyle: TextStyle(color: palette.muted, fontSize: 16),
                suffixIcon: quote == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: TextButton(
                          onPressed: () => setState(() =>
                              _cost.text = Fmt.amountInput(quote.price)),
                          style: TextButton.styleFrom(
                            foregroundColor: palette.muted,
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Güncel fiyat'),
                        ),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Değer', style: TextStyle(color: palette.muted)),
              const Spacer(),
              Text(
                canSubmit && quote != null
                    ? Fmt.money(amount * quote.price)
                    : '—',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFeatures: tabular,
                ),
              ),
            ],
          ),
          if (profit != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Kâr/zarar', style: TextStyle(color: palette.muted)),
                const Spacer(),
                ChangeText(
                  enteredCost! > 0
                      ? (quote!.price - enteredCost) / enteredCost * 100
                      : null,
                  amount: profit,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ],
          if (existing != null) ...[
            const SizedBox(height: 6),
            Text(
              'Portföyünde zaten ${Fmt.amount(existing.amount)} $unit var; üzerine eklenecek.'
              '${existing.avgCost != null && enteredCost == null ? ' Alış fiyatı boş kalırsa güncel fiyat kullanılır.' : ''}',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: canSubmit ? () => _submit(amount, unitCost) : null,
            child: Text(_isEdit ? 'Kaydet' : 'Ekle'),
          ),
          if (_isEdit) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => _delete(name!),
              style: TextButton.styleFrom(
                foregroundColor: palette.negative,
                minimumSize: const Size(64, 48),
              ),
              child: const Text('Varlığı sil'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedAsset extends StatelessWidget {
  const _SelectedAsset({
    required this.type,
    required this.code,
    required this.name,
    required this.quote,
  });

  final AssetType type;
  final String code;
  final String name;
  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        AssetAvatar(type: type, code: code),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                quote == null
                    ? 'Fiyat bulunamadı'
                    : type == AssetType.cash
                        ? 'Nakit'
                        : 'Birim fiyat ${Fmt.price(quote!.price)}',
                style: TextStyle(
                    color: palette.muted, fontSize: 13, fontFeatures: tabular),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
