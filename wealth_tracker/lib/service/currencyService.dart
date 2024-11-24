import 'dart:convert';

import 'package:wealth_tracker/model/goldAndCurrency.dart';
import 'package:http/http.dart' as http;

class CurrencyService {
  final String _url = 'https://hasanadiguzel.com.tr/api/kurgetir';

  Future<List<GoldAndCurrency>> fetchCurrencyData() async {
    try {
      final response = await http.get(Uri.parse(_url));
      // API başarılı bir şekilde yanıt verdiğinde
      if (response.statusCode == 200) {
        String jsonData = utf8.decode(response.bodyBytes);
        var decodedJson = json.decode(jsonData);
        List<dynamic> data = decodedJson['TCMB_AnlikKurBilgileri'];
        return data.map((json) => GoldAndCurrency.fromJson(json)).toList();
      } else {
        throw Exception('Veri alınırken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API çağrısı sırasında bir hata oluştu: $e');
    }
  }
}
