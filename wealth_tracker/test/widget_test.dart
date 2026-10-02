import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wealth_tracker/core/format.dart';
import 'package:wealth_tracker/main.dart';
import 'package:wealth_tracker/state/providers.dart';

import 'fakes.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  FakePriceApi? api,
  List<Map<String, Object>>? holdings,
}) async {
  PackageInfo.setMockInitialValues(
    appName: 'Kese',
    packageName: 'com.example.wealth_tracker',
    version: '3.0.0',
    buildNumber: '3',
    buildSignature: '',
  );
  SharedPreferences.setMockInitialValues({
    if (holdings != null) 'portfolio.v2': jsonEncode(holdings),
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      priceApiProvider.overrideWithValue(api ?? FakePriceApi()),
    ],
    child: const WealthTrackerApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('boş portföyden varlık eklenir ve toplam güncellenir',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('Tüm varlıkların, tek rakam.'), findsOneWidget);
    expect(find.text('KESE'), findsOneWidget);

    await tester.tap(find.text('Varlık ekle'));
    await tester.pumpAndSettle();

    // Varsayılan tür Altın; varlık seçmeden kaydedilemez.
    final addButton = find.widgetWithText(FilledButton, 'Ekle');
    expect(tester.widget<FilledButton>(addButton).onPressed, isNull);

    await tester.tap(find.text('Varlık seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gram Altın'));
    await tester.pumpAndSettle();

    // Türü değiştirmek seçimi sıfırlar (eski sürümdeki çökme hatası).
    await tester.tap(find.text('Döviz'));
    await tester.pumpAndSettle();
    expect(find.text('Varlık seç'), findsOneWidget);
    await tester.tap(find.text('Altın'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Varlık seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gram Altın'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '2,5');
    await tester.pump();
    expect(find.text('₺7.500,00'), findsOneWidget);

    // Alış fiyatı girilince kâr/zarar önizlenir.
    await tester.enterText(fields.at(1), '2800');
    await tester.pump();
    expect(find.text('₺500,00  %7,14'), findsOneWidget);

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Gram Altın'), findsOneWidget);
    // Toplam değer başlığı, dağılım kartı ve varlık satırı.
    expect(find.text('₺7.500,00'), findsNWidgets(3));
    expect(find.text('₺74,26  %1,00'), findsOneWidget);
    expect(find.bySemanticsLabel('+₺74,26, +%1,00'), findsOneWidget);
    expect(find.text('₺500,00  %7,14'), findsOneWidget);
    expect(find.text('toplam kâr/zarar'), findsOneWidget);

    // Satırlarda günlük değişim yerine toplam K/Z gösterilebilir.
    expect(find.text('%1,00'), findsOneWidget);
    await tester.tap(find.text('Bugün'));
    await tester.pumpAndSettle();
    expect(find.text('Toplam K/Z'), findsOneWidget);
    expect(find.text('%7,14'), findsOneWidget);

    // İpucu, tüm varlıkların maliyeti bilindiği için gösterilmez.
    expect(find.textContaining('Alış fiyatı girilmemiş'), findsNothing);

    // Dolu portföyde ekleme, liste başlığındaki butondan yapılır.
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Varlık ekle'), findsOneWidget);
  });

  testWidgets('tutarlar gizlenebilir ve tercih hatırlanır', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Varlık ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nakit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1000');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('₺1.000,00'), findsWidgets);

    // Görünüm panelinden gizlenir.
    await tester.tap(find.byTooltip('Görünüm').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tutarları gizle'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20)); // paneli kapat
    await tester.pumpAndSettle();
    expect(find.text('₺1.000,00'), findsNothing);
    expect(find.text(Fmt.hidden), findsWidgets);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ui.hideBalances'), isTrue);

    // Toplam değere dokunmak da açıp kapatır.
    await tester.tap(find.text(Fmt.hidden).first);
    await tester.pumpAndSettle();
    expect(find.text('₺1.000,00'), findsWidgets);
  });

  testWidgets('dağılımdaki türe dokunmak listeyi filtreler', (tester) async {
    await pumpApp(tester, holdings: [
      {'type': 'gold', 'code': 'gram-altin', 'amount': 1},
      {'type': 'currency', 'code': 'USD', 'amount': 10},
    ]);
    expect(find.text('Gram Altın'), findsOneWidget);
    expect(find.text('ABD Doları'), findsOneWidget);

    await tester.tap(find.text('Döviz'));
    await tester.pumpAndSettle();
    expect(find.text('Gram Altın'), findsNothing);
    expect(find.text('ABD Doları'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtreyi kaldır'));
    await tester.pumpAndSettle();
    expect(find.text('Gram Altın'), findsOneWidget);
  });

  testWidgets('fiyatlar dakikada bir, hata sonrası 15 sn içinde yenilenir; '
      'arka planda durur', (tester) async {
    final api = FakePriceApi();
    await pumpApp(tester, api: api);
    expect(api.currencyCalls, 1);

    await tester.pump(const Duration(seconds: 59));
    expect(api.currencyCalls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(api.currencyCalls, 2);

    // Kaynak düşerse bir sonraki turu beklemeden yeniden denenir.
    api.failCurrency = true;
    await tester.pump(const Duration(minutes: 1));
    expect(api.currencyCalls, 3);
    api.failCurrency = false;
    await tester.pump(const Duration(seconds: 15));
    expect(api.currencyCalls, 4);

    // Arka planda yenileme yapılmaz, dönüşte hemen yenilenir.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(minutes: 5));
    expect(api.currencyCalls, 4);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(api.currencyCalls, 5);
  });

  testWidgets('fiyatlar alınamazsa tekrar deneme sunulur', (tester) async {
    final api = FakePriceApi(failAll: true);
    await pumpApp(tester, api: api);

    await tester.tap(find.text('Piyasalar'));
    await tester.pumpAndSettle();
    expect(find.text('Fiyatlar alınamadı'), findsOneWidget);

    api.failAll = false;
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(find.text('ABD Doları'), findsNothing); // varsayılan sekme Altın
    expect(find.text('Gram Altın'), findsOneWidget);
  });

  testWidgets('borç eklenir ve portföyde net değer gösterilir', (tester) async {
    await pumpApp(tester, holdings: [
      {'type': 'cash', 'code': 'TRY', 'amount': 10000},
    ]);
    expect(find.text('Toplam değer'), findsOneWidget);

    await tester.tap(find.text('Borçlar'));
    await tester.pumpAndSettle();
    expect(find.text('Borç kaydı yok'), findsOneWidget);
    await tester.tap(find.text('Kayıt ekle'));
    await tester.pumpAndSettle();

    // Varsayılan: borç verdim, nakit.
    await tester.tap(find.text('Borç aldım'));
    await tester.enterText(find.widgetWithText(TextField, 'Kişi adı'), 'Ali');
    await tester.enterText(find.widgetWithText(TextField, 'Miktar'), '2500');
    await tester.pump();
    final save = find.widgetWithText(FilledButton, 'Ekle');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('BORÇLARIM'), findsOneWidget);
    expect(find.text('Net  −₺2.500,00'), findsOneWidget);

    await tester.tap(find.text('Portföy'));
    await tester.pumpAndSettle();
    expect(find.text('Net değer'), findsOneWidget);
    expect(find.text('₺7.500,00'), findsOneWidget);

    // Döküme dokunmak Borçlar sekmesine götürür.
    await tester.tap(find.textContaining('Varlıklar ₺10.000,00'));
    await tester.pumpAndSettle();
    expect(find.text('BORÇLARIM'), findsOneWidget);
  });

  testWidgets('tema uygulama içinden değiştirilir', (tester) async {
    await pumpApp(tester);
    Brightness brightness() =>
        Theme.of(tester.element(find.text('Portföy').first)).brightness;
    expect(brightness(), Brightness.light); // test ortamı açık tema

    await tester.tap(find.byTooltip('Görünüm').first);
    await tester.pumpAndSettle();
    expect(find.text('Kese · v3.0.0 (3)'), findsOneWidget);
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ui.themeMode'), 'dark');
  });

  testWidgets('maliyet ipucu kapatılınca bir daha görünmez', (tester) async {
    await pumpApp(tester, holdings: [
      {'type': 'gold', 'code': 'gram-altin', 'amount': 1},
    ]);
    await tester.tap(find.text('Bugün'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Alış fiyatı girilmemiş'), findsOneWidget);

    await tester.tap(find.byTooltip('Anladım'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Alış fiyatı girilmemiş'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ui.costHintSeen'), isTrue);
  });
}
