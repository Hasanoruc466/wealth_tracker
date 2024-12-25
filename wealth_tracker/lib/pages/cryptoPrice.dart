import 'package:flutter/material.dart';
import 'package:wealth_tracker/model/crypto.dart';
import 'package:wealth_tracker/model/goldAndCurrency.dart';

class CryptoPriceScreen extends StatefulWidget {
  final List<Crypto> cryptoDatas;

  const CryptoPriceScreen({super.key, required this.cryptoDatas});

  @override
  _CryptoPriceScreenState createState() => _CryptoPriceScreenState();
}

class _CryptoPriceScreenState extends State<CryptoPriceScreen> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Kripto", style: TextStyle(fontSize: 16)),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue, //Geri butonunu kaldırır
        ),
        body: Column(
          children: [
            DecoratedBox(decoration: BoxDecoration(color: Colors.blue[300]),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Market',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Fiyat',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.right,
                    ),
                  )
                ])),
            Expanded(
              child: SingleChildScrollView(
            // Kaydırılabilir yapıyor
            child: Table(
          columnWidths: const {
            0: FlexColumnWidth(),
            1: FixedColumnWidth(100),
          },
          children: [...widget.cryptoDatas.map<TableRow>((crypto) {
              i++;
              return TableRow(
                  decoration: BoxDecoration(
                      color:
                          i % 2 == 0 ? Colors.blue[200] : Colors.blue[100]),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(crypto.marketCode,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        crypto.currentPrice.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    )
                  ]);
            })],
        )))
          ],
        ));
  }
}
