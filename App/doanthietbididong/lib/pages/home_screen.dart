// lib/pages/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../widgets/app_topbar.dart';
import '../utils/image_utils.dart';
import '../utils/api_config.dart';
import '../models/food.dart';
import 'food_detail.dart';
import 'food_menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> categoryTags = [
    {"title": "Món ngon mỗi ngày", "image": "assets/images/mon_ngon_moi_ngay.jpg", "tag": "Món chính"},
    {"title": "Món ăn ngon đặc sản", "image": "assets/images/mon_ngon_dac_san.jpg", "tag": "Đặc sản"},
    {"title": "Đồ uống - Cocktail", "image": "assets/images/do_uong.jpg", "tag": "Đồ uống"},
    {"title": "Làm bánh - Xôi - Chè", "image": "assets/images/banh_xoi_che.jpg", "tag": "Bánh"},
    {"title": "Món nhậu", "image": "assets/images/mon_nhau.jpg", "tag": "Nhậu"},
    {"title": "Món chay", "image": "assets/images/mon_chay.jpg", "tag": "Ăn chay"},
    {"title": "Thịt - Gia vị", "image": "assets/images/thit_gia_vi.jpg", "tag": "Thịt"},
    {"title": "Món ăn sáng", "image": "assets/images/mon_an_sang.jpg", "tag": "Ăn sáng"},
  ];

  void _onSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodMenu(categoryFilter: null, initialQuery: keyword),
      ),
    );
  }

  Future<void> _handlePickImage() async {
    final file = await ImageUtils.pickImage(context);
    if (file != null) {
      await _uploadAndNavigate(file);
    }
  }

  Future<void> _uploadAndNavigate(File file) async {
    final baseUrl = ApiConfig.activeBaseUrl;
    final url = Uri.parse('${baseUrl}api/predict');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📤 Đang gửi ảnh lên server...')),
    );

    final req = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', file.path));

    try {
      final res = await req.send();
      final body = await res.stream.bytesToString();

      if (res.statusCode == 200) {
        final jsonRes = json.decode(body);

        // Nếu server trả lỗi (status: fail)
        if (jsonRes is Map && jsonRes['status'] == 'fail') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonRes['message'] ?? 'Không dự đoán được món ăn!')),
          );
          return;
        }

        // ✅ Server trả trực tiếp đối tượng món ăn
        final fi = Map<String, dynamic>.from(jsonRes);
        final key = (fi['key'] ?? '').toString();

        final food = Food(
          id: fi.containsKey('id')
              ? (fi['id'] is int ? fi['id'] : int.tryParse(fi['id'].toString()))
              : null,
          key: key,
          name: fi['name'] ?? 'Không rõ tên món ăn',
          description: fi['description'] ?? 'Chưa có mô tả cho món ăn này.',
          ingredients: List<String>.from(fi['ingredients'] ?? []),
          instructions: List<String>.from(fi['instructions'] ?? []),
          tags: List<String>.from(fi['tags'] ?? []),
          imageUrl: (fi['image'] != null && fi['image'].toString().isNotEmpty)
              ? (fi['image'].toString().startsWith('http')
              ? fi['image']
              : '${baseUrl}${fi['image'].toString().startsWith('/') ? fi['image'].toString().substring(1) : fi['image']}')
              : '${baseUrl}food_images/$key.jpg',
        );

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FoodDetailPage(food: food)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi server (${res.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Lỗi khi tải ảnh: $e')),
      );
    }
  }

  void _openCategoryByTag(String tagName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => FoodMenu(categoryFilter: tagName)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppTopBar(
        searchController: _searchController,
        onSearch: _onSearch,
        onCameraPressed: _handlePickImage,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            ...categoryTags.take(2).map((cat) {
              return GestureDetector(
                onTap: () => _openCategoryByTag(cat["tag"]!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(image: AssetImage(cat["image"]!), fit: BoxFit.cover),
                  ),
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black54]),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(cat["title"]!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryTags.length - 2,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
              itemBuilder: (context, index) {
                final cat = categoryTags[index + 2];
                return GestureDetector(
                  onTap: () => _openCategoryByTag(cat["tag"]!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(cat["image"]!, fit: BoxFit.cover),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            color: Colors.black54,
                            padding: const EdgeInsets.all(8),
                            child: Text(cat["title"]!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text("Đề xuất hôm nay", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 10),
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.shade200)),
              child: const Text("⏳ Dữ liệu đề xuất sẽ được tải từ server...", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
