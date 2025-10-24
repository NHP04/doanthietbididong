import 'package:flutter/material.dart';
import '../models/food.dart';
import '../widgets/food_item.dart';
import '../widgets/loading_tile.dart';
import '../utils/food_loader.dart';
import '../pages/food_detail.dart';

class FoodListView extends StatefulWidget {
  final FoodLoader loader;

  const FoodListView({super.key, required this.loader});

  @override
  State<FoodListView> createState() => _FoodListViewState();
}

class _FoodListViewState extends State<FoodListView> {
  @override
  void initState() {
    super.initState();
    widget.loader.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final loader = widget.loader;
    if (loader.scrollController.position.pixels >=
        loader.scrollController.position.maxScrollExtent - 200) {
      loader.loadNextPage(context).then((_) => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loader = widget.loader;

    if (loader.visible.isEmpty && loader.allFood.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: loader.scrollController,
      itemCount: loader.visible.length,
      itemBuilder: (ctx, i) {
        final item = loader.visible[i];
        if (item == null) return const LoadingTile();
        return FoodItem(
          food: item,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FoodDetailPage(food: item)),
          ),
        );
      },
    );
  }
}
