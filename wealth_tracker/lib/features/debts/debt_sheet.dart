import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models/asset_type.dart';
import '../../data/models/debt.dart';
import '../../data/models/quote.dart';
import '../../state/providers.dart';
import '../../widgets/asset_field.dart';
import '../../widgets/inputs.dart';
import '../holding/asset_picker.dart';

/// [debt] verilirse düzenleme, verilmezse ekleme modunda açılır.
Future<void> showDebtSheet(
  BuildContext context, {
  Debt? debt,
  DebtDirection direction = DebtDirection.lent,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DebtSheet(debt: debt, direction: direction),
  );
}

/// Kaydı "Geri al" seçeneği sunan bir bildirimle kapatır.
void removeDebtWithUndo({
  required DebtsNotifier notifier,
  required ScaffoldMessengerState messenger,
  required String id,
}) {
  final removed = notifier.remove(id);
  if (removed == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('${removed.person} kaydı kapatıldı'),
      action: SnackBarAction(
        label: 'Geri al',
        onPressed: () => notifier.save(removed),
      ),
    ));
}

class DebtSheet extends ConsumerStatefulWidget {
  const DebtSheet({super.key, this.debt, required this.direction});

  final Debt? debt;
  final DebtDirection direction;

  @override
  ConsumerState<DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends ConsumerState<DebtSheet> {
  late DebtDirection _direction = widget.debt?.direction ?? widget.direction;
  late AssetType _type = widget.debt?.type ?? AssetType.cash;
  late String? _code = widget.debt?.code ?? Quote.cash.code;
  late DateTime? _dueDate = widget.debt?.dueDate;
  late final _person = TextEditingController(text: widget.debt?.person);
  late final _amount = TextEditingController(
    text: widget.debt == null ? '' : Fmt.amountInput(widget.debt!.amount),
  );
  late final _note = TextEditingController(text: widget.debt?.note);

  bool get _isEdit => widget.debt != null;

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _selectType(AssetType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _code = type == AssetType.cash ? Quote.cash.code : null;
    });
  }

  Future<void> _pickAsset() async {
    final quote = await showAssetPicker(context, _type);
    if (quote != null && mounted) setState(() => _code = quote.code);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      helpText: 'Vade tarihi',
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  void _submit(double amount) {
    final note = _note.text.trim();
    ref.read(debtsProvider.notifier).save(Debt(
          id: widget.debt?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          direction: _direction,
          person: _person.text.trim(),
          type: _type,
          code: _code!,
          amount: amount,
          dueDate: _dueDate,
          note: note.isEmpty ? null : note,
        ));
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _close() {
    final notifier = ref.read(debtsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    removeDebtWithUndo(
      notifier: notifier,
      messenger: messenger,
      id: widget.debt!.id,
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
    final canSubmit = _person.text.trim().isNotEmpty &&
        code != null &&
        amount != null &&
        amount > 0;
    final hintStyle = TextStyle(
        color: palette.muted, fontSize: 16, fontWeight: FontWeight.w400);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEdit ? 'Kaydı düzenle' : 'Borç / alacak ekle',
              style: context.text.titleLarge),
          const SizedBox(height: 20),
          Segmented<DebtDirection>(
            values: DebtDirection.values,
            value: _direction,
            label: (d) => d.action,
            onChanged: (d) => setState(() => _direction = d),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _person,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Kişi adı',
              hintStyle: hintStyle,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          Text('Ne cinsinden?',
              style: TextStyle(color: palette.muted, fontSize: 13)),
          const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [Fmt.amountInputFormatter],
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFeatures: tabular,
            ),
            decoration: InputDecoration(
              hintText: 'Miktar',
              hintStyle: hintStyle,
              suffixText: unitLabel(_type, code),
              suffixStyle: TextStyle(color: palette.muted, fontSize: 14),
            ),
          ),
          if (_type != AssetType.cash) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Bugünkü değeri', style: TextStyle(color: palette.muted)),
                const Spacer(),
                Text(
                  amount != null && quote != null
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
          ],
          const SizedBox(height: 12),
          _DueDateField(
            date: _dueDate,
            onTap: _pickDueDate,
            onClear: () => setState(() => _dueDate = null),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 120,
            decoration: InputDecoration(
              hintText: 'Not (isteğe bağlı)',
              hintStyle: hintStyle,
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: canSubmit ? () => _submit(amount) : null,
            child: Text(_isEdit ? 'Kaydet' : 'Ekle'),
          ),
          if (_isEdit) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: _close,
              style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
              child: Text(_direction == DebtDirection.lent
                  ? 'Geri ödendi, kaydı kapat'
                  : 'Borcu ödedim, kaydı kapat'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final date = this.date;
    return Material(
      color: palette.field,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              Icon(Icons.event_outlined, size: 20, color: palette.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  date == null
                      ? 'Vade tarihi (isteğe bağlı)'
                      : 'Vade: ${Fmt.date(date)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: date == null ? palette.muted : null,
                    fontWeight: date == null ? null : FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: date == null
                    ? null
                    : IconButton(
                        onPressed: onClear,
                        tooltip: 'Vadeyi kaldır',
                        iconSize: 18,
                        color: palette.muted,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
