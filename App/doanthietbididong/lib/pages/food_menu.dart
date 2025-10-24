// lib/pages/food_menu.dart
import 'dart:async';
import 'dart:math';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';

import '../models/food.dart';
import '../utils/api_service.dart';
import '../utils/api_config.dart';
import '../widgets/food_item.dart';
import '../widgets/loading_tile.dart';
import 'food_detail.dart';
import 'predict_page.dart';

class FoodMenu extends StatefulWidget {
  final String? categoryFilter;
  final String? initialQuery;
  const FoodMenu({super.key, this.categoryFilter, this.initialQuery});

  @override
  State<FoodMenu> createState() => _FoodMenuState();
}

class _FoodMenuState extends State<FoodMenu> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Food> allFood = [];
  List<Food> filtered = [];
  List<Food?> visible = [];

  static const int pageSize = 15;
  bool isLoading = false;
  bool allLoaded = false;
  int page = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initialize();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initialize() async {
    await _fetchData();

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _applySearch(widget.initialQuery!.trim());
    }
  }

  Future<void> _fetchData() async {
    try {
      print('🌍 Kết nối server: ${ApiConfig.activeBaseUrl}');
      List<Food> result = [];

      if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
        result = await ApiService.fetchFoodsByTag(widget.categoryFilter!);
        print('📂 Lọc theo tag "${widget.categoryFilter}" → ${result.length} món');
      } else {
        result = await ApiService.fetchFoods();
        print('📦 Tải toàn bộ món ăn: ${result.length} món');
      }

      setState(() {
        allFood = result;
        filtered = List.from(result);
      });

      _refreshVisible();
    } catch (e) {
      print('⚠️ Lỗi tải dữ liệu: $e');
      _showSnack('❌ Không thể kết nối đến server.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        !allLoaded) {
      _loadNextPage();
    }
  }

  void _refreshVisible() {
    setState(() {
      visible.clear();
      page = 0;
      allLoaded = false;
    });
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (isLoading || allLoaded) return;

    setState(() {
      isLoading = true;
      visible.add(null);
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      if (visible.isNotEmpty && visible.last == null) visible.removeLast();
    });

    final start = page * pageSize;
    final end = min(start + pageSize, filtered.length);

    if (start < end) {
      final next = filtered.sublist(start, end);
      for (var f in next) {
        precacheImage(NetworkImage(f.imageUrl), context);
      }

      setState(() {
        visible.addAll(next);
        page++;
        if (visible.length >= filtered.length) allLoaded = true;
      });
    } else {
      setState(() => allLoaded = true);
    }

    setState(() => isLoading = false);
  }

  static String _norm(String s) => removeDiacritics(s).toLowerCase();

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applySearch(text);
    });
  }

  void _applySearch(String text) {
    final q = _norm(text.trim());
    setState(() {
      filtered = q.isEmpty
          ? List.from(allFood)
          : allFood.where((f) => _norm(f.name).contains(q) || _norm(f.description).contains(q)).toList();
    });
    _refreshVisible();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryTitle = widget.categoryFilter ?? 'Danh sách món ăn';

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Tìm món (có hoặc không dấu)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              itemCount: visible.length,
              itemBuilder: (ctx, i) {
                final item = visible[i];
                if (item == null) return const LoadingTile();
                return FoodItem(
                  food: item,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FoodDetailPage(food: item),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PredictPage()),
          );
        },
        backgroundColor: Colors.orange,
        label: const Text('Dự đoán món ăn'),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }
}
