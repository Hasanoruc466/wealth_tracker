import 'package:flutter/material.dart';
import 'package:wealth_tracker/model/goldAndCurrency.dart';

class GoldOrCurrenyPriceScreen extends StatefulWidget {
  final List<GoldAndCurrency> goldTypes;
  final bool isGold;

  const GoldOrCurrenyPriceScreen(
      {super.key, required this.goldTypes, required this.isGold});

  @override
  _GoldOrCurrenyPriceScreenState createState() =>
      _GoldOrCurrenyPriceScreenState();
}

class _GoldOrCurrenyPriceScreenState extends State<GoldOrCurrenyPriceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.isGold ? "Altın Fiyatları" : "Döviz Fiyatları",
              style: const TextStyle(fontSize: 16)),
          automaticallyImplyLeading: false,
          backgroundColor: widget.isGold ? Colors.amber[200] : Colors.lightGreen[300], //Geri butonunu kaldırır
        ),
        body: Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
                // Kaydırılabilir yapıyor
                child: Table(
              columnWidths: const {
                0: FlexColumnWidth(), 
                1: FixedColumnWidth(100), 
                2: FixedColumnWidth(100), 
              },
              children: [
                const TableRow(children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Varlık', style: TextStyle(fontSize: 14),),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Alış Fiyatı', style: TextStyle(fontSize: 14), textAlign: TextAlign.right,),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Satış Fiyatı', style: TextStyle(fontSize: 14), textAlign: TextAlign.right,),
                  ),
                ]),
                ...widget.goldTypes.map<TableRow>((gold) {
                  return TableRow(children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(gold.fullName,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(gold.buy.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12), textAlign: TextAlign.right,),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(gold.sell.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12), textAlign: TextAlign.right,),
                    ),
                  ]);
                })
              ],
            ))));
  }
}
