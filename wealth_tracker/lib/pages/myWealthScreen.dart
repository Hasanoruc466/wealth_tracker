import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wealth_tracker/model/asset.dart';
import 'package:wealth_tracker/model/crypto.dart';
import 'package:wealth_tracker/service/cryptoService.dart';
import 'package:wealth_tracker/service/currencyService.dart';
import 'package:wealth_tracker/service/goldService.dart';
import 'package:wealth_tracker/service/shared_prefences.dart';
import 'addAssetScreen.dart';
import 'package:wealth_tracker/model/goldAndCurrency.dart';

class MyWealthScreen extends StatefulWidget {
  final List<Crypto> cryptoData;
  final List<GoldAndCurrency> currencyData;
  final List<GoldAndCurrency> goldData;

  const MyWealthScreen({super.key,
      required this.cryptoData,
      required this.currencyData,
      required this.goldData});

  @override
  _MyWealthScreenState createState() => _MyWealthScreenState();
}

class _MyWealthScreenState extends State<MyWealthScreen> {
  final List<Map<String, dynamic>> _assets = [];
  List<Asset> assetList = [];
  double _totalValue = 0.0;
  bool _isLoading = true;

  // Sayfa ilk kez açıldığında veriyi yükle
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    assetList = await loadAssetList();
    _getAssets();
    setState(() {
      _isLoading = false;
    });
  }

  void _getAssets() {
    if (assetList.isNotEmpty) {
      _totalValue = 0;
      for (var asset in assetList) {
        double assetPrice;
        if (asset.assetType == 'Döviz') {
          assetPrice =
              widget.currencyData!.firstWhere((c) => c.fullName == asset.name).buy;
        } else if (asset.assetType == 'Kripto') {
          assetPrice = widget.cryptoData!
              .firstWhere((c) => c.assetCode == asset.name)
              .currentPrice;
        } else if (asset.assetType == 'Altın') {
          assetPrice =
              widget.goldData!.firstWhere((c) => c.fullName == asset.name).buy;
        } else {
          assetPrice = 1;
        }
        double total = asset.amount * assetPrice;
        _totalValue += total;
        setState(() {
          _assets.add({
            'type': asset.name,
            'amount': asset.amount,
            'assetType': asset.assetType,
            'price': assetPrice,
            'total': total,
          });
        });
      }
    }else {
    // Eğer assetList boşsa, toplam değeri sıfırla
    setState(() {
      _totalValue = 0;
      _assets.clear();
    });
  }
  }

  void _addAsset(String assetName, double amount, String assetType) {
    int index = assetList.indexWhere((a) => a.name == assetName);
    Asset asset = assetList.firstWhere((a) => a.name == assetName,
        orElse: () =>
            Asset(assetType: assetType, name: assetName, amount: amount));
    if (index != -1) {
      asset.amount += amount;
      assetList.removeAt(index);
    }
    assetList.add(asset);
    removeAssetList();
    saveAssetList(assetList);
    _assets.clear();
    _getAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Varlıklarım", style: TextStyle(fontSize: 16)),
        automaticallyImplyLeading: false, //Geri butonunu kaldırır
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "Toplam Bakiye: ${NumberFormat('#,##0.00', 'tr').format(_totalValue)} TL",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _assets.length,
                    itemBuilder: (context, index) {
                      final asset = _assets[index];
                      NumberFormat amountFormat = NumberFormat.decimalPattern('tr')
                        ..maximumFractionDigits = 10
                        ..minimumFractionDigits = 2;
                      return ListTile(
                        title: Text("${asset['type']}",
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Metinleri sola hizala
                          children: [
                            Text(
                              "Miktar: ${amountFormat.format(asset['amount'])}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "Fiyat: ${NumberFormat('#,##0.00', 'tr').format(asset['price'])} TL",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "Toplam: ${NumberFormat('#,##0.00', 'tr').format(asset['total'])} TL",
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight
                                      .bold), // Toplam için kalın yazı
                            ),
                          ],
                        ),
                        trailing: Text("${asset['assetType']}",
                            style: const TextStyle(fontSize: 14)),
                        onTap: () => _ontListTileTap(context, asset),
                        onLongPress: () => _onListTileLongPress(context, asset),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.currencyData != null && widget.cryptoData != null
            ? () {
                _openAddAssetPopup(context);
              }
            : null,
        backgroundColor: const Color.fromARGB(255, 12, 52, 68),
        child: const Icon(Icons.add, color: Color.fromARGB(255, 241, 246, 250)),
      ),
    );
  }

  void _openAddAssetPopup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAssetScreen(
          onAdd: _addAsset,
          cryptoData: widget.cryptoData!,
          currencyData: widget.currencyData!,
          goldData: widget.goldData!,
        ),
      ),
    );
  }

  void _ontListTileTap(BuildContext context, Map<String, dynamic> paramAsset) {
    double amount = paramAsset['amount'];
    final amountController = TextEditingController(text: amount.toString());
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Güncelle", style: TextStyle(fontSize: 14)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Miktar",
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
            ]),
            actions: [
              TextButton(
                  onPressed: () {
                    int index = assetList
                        .indexWhere((a) => a.name == paramAsset['type']);
                    Asset? asset = assetList
                        .firstWhere((a) => a.name == paramAsset['type']);
                    asset.amount =
                        double.tryParse(amountController.text) ?? 0.0;
                    assetList.removeAt(index);
                    assetList.add(asset);
                    removeAssetList();
                    saveAssetList(assetList);
                    _assets.clear();
                    _getAssets();
                    Navigator.of(context).pop(); // Popup'ı kapat
                  },
                  child: const Text("Onayla", style: TextStyle(fontSize: 14)))
            ],
          );
        });
  }

  void _onListTileLongPress(
      BuildContext context, Map<String, dynamic> paramAsset) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Silme", style: TextStyle(fontSize: 14)),
            content: const Text("Veriyi silmek istediğinize emin misiniz?",
                style: TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                  onPressed: () {
                    int index = assetList
                        .indexWhere((a) => a.name == paramAsset['type']);
                    assetList.removeAt(index);
                    removeAssetList();
                    saveAssetList(assetList);
                    _assets.clear();
                    _getAssets();
                    Navigator.of(context).pop(); // Popup'ı kapat
                  },
                  child: const Text("Onayla", style: TextStyle(fontSize: 14)))
            ],
          );
        });
  }
}
