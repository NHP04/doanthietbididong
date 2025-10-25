import 'package:flutter/material.dart';
import '../models/category.dart';
import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;

  const CategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        SizedBox(
          height: screenWidth * 0.55,
          child: CategoryCard(category: categories[0]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: screenWidth * 0.55,
          child: CategoryCard(category: categories[1]),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length - 2,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return CategoryCard(category: categories[index + 2]);
          },
        ),
      ],
    );
  }
}
