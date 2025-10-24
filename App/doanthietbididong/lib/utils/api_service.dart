// lib/utils/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/food.dart';
import 'api_config.dart';
import 'package:diacritic/diacritic.dart';

class ApiService {
  static String get baseUrl =>
      ApiConfig.activeBaseUrl.endsWith('/')
          ? ApiConfig.activeBaseUrl
          : '${ApiConfig.activeBaseUrl}/';
  static String get dataUrl => '${baseUrl}api/dishes';
  static String get predictUrl => '${baseUrl}api/predict';
  static List<Food>? _cachedFoods;

  static Future<List<Food>> fetchFoods() async {
    if (_cachedFoods != null && _cachedFoods!.isNotEmpty) {
      print('💾 Dùng cache món ăn cũ: ${_cachedFoods!.length} món');
      return _cachedFoods!;
    }

    try {
      final uri = Uri.parse(dataUrl);
      final res = await http.get(uri).timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        throw HttpException('Server error: ${res.statusCode}');
      }

      final body = utf8.decode(res.bodyBytes);
      final List<dynamic> arr = jsonDecode(body);
      _cachedFoods = arr.map((e) => Food.fromJson(e as Map<String, dynamic>, baseUrl)).toList();
      return _cachedFoods!;
    } catch (e) {
      print('! fetchFoods error: $e');
      return _cachedFoods ?? [];
    }
  }

  static Future<List<Food>> fetchFoodsByTag(String tagName) async {
    try {
      final allFoods = await fetchFoods();

      final normalizedTag = removeDiacritics(tagName.toLowerCase().trim());

      final filtered = allFoods.where((f) {
        final tags = f.tags.map((t) => removeDiacritics(t.toLowerCase())).toList();
        return tags.contains(normalizedTag);
      }).toList();

      print('🎯 Lọc theo tag "$tagName" → ${filtered.length} món');
      return filtered;
    } catch (e) {
      print('⚠️ fetchFoodsByTag error: $e');
      return [];
    }
  }

  static Future<Food> fetchDishDetail(int id) async {
    try {
      final uri = Uri.parse('${baseUrl}api/dish/$id');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw HttpException('Server error: ${res.statusCode}');
      }

      final Map<String, dynamic> jsonData = jsonDecode(utf8.decode(res.bodyBytes));
      return Food.fromJson(jsonData, baseUrl);
    } catch (e) {
      print('⚠️ fetchDishDetail error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> predict(File imageFile) async {
    try {
      final uri = Uri.parse(predictUrl);
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(body);
      } else {
        throw HttpException('Predict error: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ predict error: $e');
      rethrow;
    }
  }
}
