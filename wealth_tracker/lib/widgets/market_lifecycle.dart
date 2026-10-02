import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// Uygulama arka plana geçince fiyat yenilemeyi durdurur, öne gelince
/// fiyatları hemen yeniler.
class MarketLifecycle extends ConsumerStatefulWidget {
  const MarketLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MarketLifecycle> createState() => _MarketLifecycleState();
}

class _MarketLifecycleState extends ConsumerState<MarketLifecycle> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onHide: () => ref.read(marketProvider.notifier).pause(),
      onShow: () => ref.read(marketProvider.notifier).resume(),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
