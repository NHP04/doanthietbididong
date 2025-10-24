// lib/pages/predict_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../utils/api_config.dart';
import '../models/food.dart';
import 'food_detail.dart';

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
      await _uploadImage();
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() => _loading = true);

    final baseUrl = ApiConfig.activeBaseUrl;
    final url = Uri.parse('${baseUrl}api/predict');

    final req = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));

    try {
      final res = await req.send();
      final body = await res.stream.bytesToString();

      if (res.statusCode == 200) {
        final jsonRes = json.decode(body);

        // server có thể trả {"status":"fail",...}
        if (jsonRes is Map && jsonRes['status'] == 'fail') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonRes['message'] ?? 'Không dự đoán được')),
          );
          return;
        }

        // Nếu server trả trực tiếp object món ăn
        final foodInfo = jsonRes as Map<String, dynamic>;

        // Tạo Food (sử dụng trường 'image' nếu có)
        final imageField = foodInfo['image'] as String?; // ex: "/food_images/key.jpg"
        final imageUrl = (imageField != null && imageField.isNotEmpty)
            ? (imageField.startsWith('http') ? imageField : '${baseUrl}${imageField.startsWith('/') ? imageField.substring(1) : imageField}')
            : '${baseUrl}food_images/${foodInfo['key']}.jpg';

        final food = Food(
          key: foodInfo['key'] ?? '',
          name: foodInfo['name'] ?? 'Không rõ tên',
          description: foodInfo['description'] ?? '',
          ingredients: List<String>.from(foodInfo['ingredients'] ?? []),
          instructions: List<String>.from(foodInfo['instructions'] ?? []),
          imageUrl: imageUrl,
          tags: (foodInfo['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => FoodDetailPage(food: food)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi server (${res.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dự đoán món ăn từ ảnh')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_selectedImage!, height: 220, fit: BoxFit.cover),
            )
                : Container(
              height: 220,
              width: double.infinity,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Text('Chưa chọn ảnh', style: TextStyle(color: Colors.black54)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.image),
              label: const Text('Chọn ảnh từ thư viện'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImageFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Chụp ảnh từ camera'),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
