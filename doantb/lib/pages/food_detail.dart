// lib/pages/food_detail.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food.dart';
import '../utils/api_service.dart';
import '../widgets/app_topbar.dart';
import '../pages/predict_page.dart';
import '../pages/food_menu.dart';

class FoodDetailPage extends StatefulWidget {
  final Food food;
  const FoodDetailPage({super.key, required this.food});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late Food _food;
  bool _loading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  static const String _favKey = 'favorite_dishes';
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _food = widget.food;
    _searchController.text = '';
    _loadFavorites();
    if ((_food.ingredients.isEmpty || _food.instructions.isEmpty) && _food.id != null) {
      _fetchDetail(_food.id!);
    }
  }

  Future<void> _loadFavorites() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_favKey) ?? [];
    _favorites = list.toSet();
    setState(() {});
  }

  String _favTokenForFood(Food f) {
    if (f.id != null) return 'id:${f.id}';
    return 'key:${f.key}';
  }

  bool _isFavorite(Food f) {
    return _favorites.contains(_favTokenForFood(f));
  }

  Future<void> _toggleFavorite() async {
    final token = _favTokenForFood(_food);
    final sp = await SharedPreferences.getInstance();
    if (_favorites.contains(token)) {
      _favorites.remove(token);
    } else {
      _favorites.add(token);
    }
    await sp.setStringList(_favKey, _favorites.toList());
    setState(() {});
    final msg = _favorites.contains(token) ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích';
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail(int id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final full = await ApiService.fetchDishDetail(id);
      setState(() {
        _food = full;
      });
    } catch (e) {
      setState(() {
        _error = 'Không lấy được chi tiết: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodMenu(categoryFilter: null, initialQuery: q)),
    );
  }

  void _openTag(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodMenu(categoryFilter: tag)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppTopBar(
        searchController: _searchController,
        onSearch: _onSearch,
        onCameraPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictPage()));
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: _food.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (c, s) => Container(color: Colors.grey[300]),
                    errorWidget: (c, s, e) => Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(Icons.fastfood_outlined, size: 56),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 70,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black45],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: Text(
                    _food.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 2))],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _food.description.isNotEmpty ? _food.description : 'Chưa có mô tả cho món này.',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),
          if (_food.tags.isNotEmpty) ...[
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _food.tags.map((t) {
                return ActionChip(
                  label: Text(t),
                  onPressed: () => _openTag(t),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          const Text('Nguyên liệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_food.ingredients.isEmpty)
            const Text('Chưa có nguyên liệu cho món này.', style: TextStyle(color: Colors.black54))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _food.ingredients.map((ing) {
                return Chip(
                  label: Text(ing, style: const TextStyle(fontSize: 13)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.orange.shade100),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 16),

          const Text('Cách nấu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_food.instructions.isEmpty)
            const Text('Chưa có hướng dẫn cho món này.', style: TextStyle(color: Colors.black54))
          else
            Column(
              children: _food.instructions.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final text = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              idx.toString(),
                              style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isFavorite(_food) ? Colors.redAccent : Colors.orange,
        child: Icon(_isFavorite(_food) ? Icons.favorite : Icons.favorite_border),
        onPressed: _toggleFavorite,
      ),
    );
  }
}
