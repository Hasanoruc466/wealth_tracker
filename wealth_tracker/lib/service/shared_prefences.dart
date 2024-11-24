import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wealth_tracker/model/asset.dart';

Future<void> saveAssetList(List<Asset> list) async {
  final prefs = await SharedPreferences.getInstance();

  List<String> jsonList = list.map((asset) => jsonEncode(asset.toJson())).toList();
  await prefs.setStringList("assets", jsonList);
}

// Asset listesini yükleme
Future<List<Asset>> loadAssetList() async {
  final prefs = await SharedPreferences.getInstance();
  
  // 'assets' anahtarı altında bir liste var mı kontrol ediyoruz
  List<String>? jsonList = prefs.getStringList('assets');
  if (jsonList != null) {
    // JSON dizisini, Asset listesine dönüştür
    return jsonList.map((jsonItem) {
      return Asset.fromJson(json.decode(jsonItem));
    }).toList();
  }
  
  return [];  // Eğer veri yoksa boş bir liste döner
}

// Asset listesini silme
Future<void> removeAssetList() async {
  final prefs = await SharedPreferences.getInstance();
  
  // 'assets' anahtarını sileriz
  await prefs.remove('assets');
}