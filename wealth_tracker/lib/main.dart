import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wealth_tracker/model/asset.dart';
import 'package:wealth_tracker/model/crypto.dart';
import 'package:wealth_tracker/pages/cryptoPrice.dart';
import 'package:wealth_tracker/pages/goldOrCurrencyPriceScreen.dart';
import 'package:wealth_tracker/pages/myWealthScreen.dart';
import 'package:wealth_tracker/service/cryptoService.dart';
import 'package:wealth_tracker/service/currencyService.dart';
import 'package:wealth_tracker/service/goldService.dart';
import 'package:wealth_tracker/service/shared_prefences.dart';
import 'pages/addAssetScreen.dart';
import 'package:wealth_tracker/model/goldAndCurrency.dart';

void main() {
  runApp(const WealthTracker());
}

class WealthTracker extends StatelessWidget {
  const WealthTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen()
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
final CryptoService _cryptoService = CryptoService();
  final CurrencyService _currencyService = CurrencyService();
  final GoldService _goldService = GoldService();
  List<Crypto> cryptoData = [];
  List<GoldAndCurrency> currencyData = [];
  List<GoldAndCurrency> goldData = [];
   List<Widget> _pages = [];
  @override
  void initState() {
    super.initState();
    fetchCryptoData();
  }
   void fetchCryptoData() async {
    currencyData = await _currencyService.fetchCurrencyData();
    cryptoData = await _cryptoService.fetchCryptoData();
    goldData = await _goldService.fetchGoldData();
    setState(() {
      _pages = [
        MyWealthScreen(cryptoData: cryptoData, currencyData: currencyData, goldData: goldData),
        GoldOrCurrenyPriceScreen(goldTypes: goldData, isGold: true),
        GoldOrCurrenyPriceScreen(goldTypes: currencyData, isGold: false),
        CryptoPriceScreen(cryptoDatas: cryptoData)
      ];
    });
  }
  int _selectedIndex = 0; // Başlangıçta seçili olan sekme

  // Sekmeye tıklandığında çağrılacak fonksiyon
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.isNotEmpty ? _pages[_selectedIndex] :  const Center(child: CircularProgressIndicator()), // Seçilen sayfayı göster
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Varlıklarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_outlined),
            label: 'Altın',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange_outlined),
            label: 'Döviz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_bitcoin_outlined),
            label: 'Kripto Varlıklar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
