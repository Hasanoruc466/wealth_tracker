import 'package:flutter/material.dart';
import 'package:wealth_tracker/model/crypto.dart';
import 'package:wealth_tracker/model/goldAndCurrency.dart';

class AddAssetScreen extends StatefulWidget {
  final Function(String, double, String) onAdd;
  final List<Crypto> cryptoData;
  final List<GoldAndCurrency> currencyData;
  final List<GoldAndCurrency> goldData;

  const AddAssetScreen(
      {super.key,
      required this.onAdd,
      required this.cryptoData,
      required this.currencyData,
      required this.goldData});

  @override
  _AddAssetScreenState createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _amountController = TextEditingController();
  String _selectedAsset = "";
  String _selectedAssetType = "Döviz";
  final List<String> _assetType = <String>["Döviz", "Altın", "Kripto"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Varlık Ekle", style: TextStyle(fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.all(20),
                child: DropdownButtonFormField<String>(
                  value: _selectedAssetType,
                  items: _assetType
                      .map((asset) => DropdownMenuItem<String>(
                            value: asset,
                            child: Text(asset,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAssetType = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Varlık Türü",
                    border: OutlineInputBorder(),
                  ),
                )),
            const SizedBox(height: 16),
            Container(
                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: DropdownButtonFormField<String>(
                  items: _getDropdownItems(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAsset = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Varlık Türü",
                    border: OutlineInputBorder(),
                  ),
                )),
            const SizedBox(height: 16),
            Container(
                margin: const EdgeInsets.only(left: 20, right: 20),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Miktar",
                    border: OutlineInputBorder(),
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
                width: 200.0,
                child: ElevatedButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    if (_selectedAsset != "" && amount != 0) {
                      widget.onAdd(_selectedAsset, amount, _selectedAssetType);
                      Navigator.pop(context);
                    } else {
                      showSnackBar(
                          context,
                          "Lütfen ilgili alanları doldurun...",
                          const Color.fromRGBO(255, 215, 0, 1.0));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 12, 52, 68),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Kaydet",
                      style: TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 241, 246, 250))),
                )),
          ],
        ),
      ),
    );
  }

  void showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  List<DropdownMenuItem<String>>? _getDropdownItems() {
    if (_selectedAssetType == 'Döviz') {
      return widget.currencyData
          .map<DropdownMenuItem<String>>((GoldAndCurrency currency) {
        return DropdownMenuItem<String>(
          value: currency.fullName,
          child: Text(currency.fullName, style: const TextStyle(fontSize: 14)),
        );
      }).toList();
    } else if (_selectedAssetType == 'Kripto') {
      return widget.cryptoData.map<DropdownMenuItem<String>>((Crypto crypto) {
        return DropdownMenuItem<String>(
          value: crypto.assetCode,
          child: Text(crypto.assetCode, style: const TextStyle(fontSize: 14)),
        );
      }).toList();
    } else {
      return widget.goldData
          .map<DropdownMenuItem<String>>((GoldAndCurrency gold) {
        return DropdownMenuItem<String>(
          value: gold.fullName,
          child: Text(gold.fullName, style: const TextStyle(fontSize: 14)),
        );
      }).toList();
    }
  }
}
