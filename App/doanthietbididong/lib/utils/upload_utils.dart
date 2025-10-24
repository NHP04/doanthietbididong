import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../models/food.dart';
import '../pages/food_detail.dart';

class UploadUtils {
  static Future<void> uploadImage(BuildContext context, File file) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📤 Đang gửi ảnh lên server...')),
    );

    try {
      final uri = Uri.parse('${ApiConfig.activeBaseUrl}api/predict');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonRes = json.decode(body);

        if (jsonRes is Map<String, dynamic> && jsonRes.containsKey('id')) {
          final baseUrl = ApiConfig.activeBaseUrl.endsWith('/')
              ? ApiConfig.activeBaseUrl
              : '${ApiConfig.activeBaseUrl}/';

          final food = Food.fromJson(jsonRes, baseUrl);

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FoodDetailPage(food: food)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Không nhận được thông tin món ăn từ server.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gửi thất bại: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Lỗi khi gửi ảnh: $e')),
      );
    }
  }
}
