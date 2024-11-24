import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wealth_tracker/model/crypto.dart';

class CryptoService {
  // API URL'si
  final String _url = "https://api4.bitlo.com/market/ticker/all";

  // API çağrısı
  Future<List<Crypto>> fetchCryptoData() async {
    try {
      final response = await http.get(Uri.parse(_url));
      // API başarılı bir şekilde yanıt verdiğinde
      if (response.statusCode == 200) {
       List<dynamic> data = json.decode(response.body);
       return data.map((json)  {
          String marketCode = json['marketCode'] as String;
          if(marketCode.contains("TRY")){
            return Crypto.fromJson(json);
          }
          else{
            return Crypto(marketCode: "0", assetCode: "0", currentPrice: 0);
          }
        }).where((crypto) => crypto.assetCode != "0").toList();
      } else {
        throw Exception('Veri alınırken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API çağrısı sırasında bir hata oluştu: $e');
    }
  }
}
