import 'dart:convert';

import 'package:wealth_tracker/model/goldAndCurrency.dart';
import 'package:http/http.dart' as http;
import 'package:wealth_tracker/utils/stringUtils.dart';

class GoldService {
  final String _url = 'https://finans.truncgil.com/today.json';

  Future<List<GoldAndCurrency>> fetchGoldData() async {
    try {
      final response = await http.get(Uri.parse(_url));

      List<GoldAndCurrency> list = [];
      // API başarılı bir şekilde yanıt verdiğinde
      if (response.statusCode == 200) {
        String utf8Data = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(utf8Data);
        jsonData.forEach((key, value) {
          if (key != 'Update_Date') {
            String goldType = getGoldName(key);
            if (goldType != "") {
              String buyStr = value['Alış'] as String;
              String sellStr = value['Satış'] as String;
              GoldAndCurrency goldAndCurrency = GoldAndCurrency(
                  fullName: goldType,
                  buy: double.parse(buyStr.replaceAll(".", "").replaceAll(",", ".")),
                  sell: double.parse(sellStr.replaceAll(".", "").replaceAll(",", ".")));
              list.add(goldAndCurrency);
            }
          }
        });
        return list;
      } else {
        throw Exception('Veri alınırken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API çağrısı sırasında bir hata oluştu: $e');
    }
  }
}
