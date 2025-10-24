import 'dart:async';
import 'dart:math';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import '../models/food.dart';
import '../utils/api_service.dart';
import '../utils/api_config.dart';

class FoodLoader {
  final ScrollController scrollController = ScrollController();
  final int pageSize;
  final List<Food> allFood = [];
  final List<Food> filtered = [];
  final List<Food?> visible = [];
  bool isLoading = false;
  bool allLoaded = false;
  int page = 0;
  Timer? _debounce;

  FoodLoader({this.pageSize = 15});

  static String _normalize(String s) => removeDiacritics(s).toLowerCase();

  Future<List<Food>> fetchData(String? tagName) async {
    print('🌍 Kết nối server: ${ApiConfig.activeBaseUrl}');
    try {
      List<Food> result = await ApiService.fetchFoods();
      print('📦 Đã tải ${result.length} món ăn');
      if (tagName != null && tagName.isNotEmpty) {
        final normTag = _normalize(tagName);
        result = result.where((food) {
          final tags = food.tags.map((t) => _normalize(t));
          return tags.any((t) => t.contains(normTag));
        }).toList();
        print('📂 Lọc theo tag "$tagName" → ${result.length} món');
      }

      allFood
        ..clear()
        ..addAll(result);
      filtered
        ..clear()
        ..addAll(result);

      resetPaging();
      return result;
    } catch (e) {
      print('⚠️ Lỗi tải dữ liệu: $e');
      return [];
    }
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _normalize(query.trim());
      filtered
        ..clear()
        ..addAll(q.isEmpty
            ? allFood
            : allFood.where((f) => _normalize(f.name).contains(q)));
      resetPaging();
    });
  }

  void resetPaging() {
    visible.clear();
    page = 0;
    allLoaded = false;
  }

  Future<void> loadNextPage(BuildContext context) async {
    if (isLoading || allLoaded) return;
    isLoading = true;
    visible.add(null);

    await Future.delayed(const Duration(milliseconds: 400));

    if (visible.isNotEmpty && visible.last == null) visible.removeLast();

    final start = page * pageSize;
    final end = min(start + pageSize, filtered.length);

    if (start < end) {
      final next = filtered.sublist(start, end);
      for (var f in next) {
        precacheImage(NetworkImage(f.imageUrl), context);
      }
      visible.addAll(next);
      page++;
      if (visible.length >= filtered.length) allLoaded = true;
    } else {
      allLoaded = true;
    }

    isLoading = false;
  }
}
