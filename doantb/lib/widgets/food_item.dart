// lib/widgets/food_item.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/food.dart';

class FoodItem extends StatelessWidget {
  final Food food;
  final VoidCallback? onTap;

  const FoodItem({super.key, required this.food, this.onTap});


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.orange.withOpacity(0.15),
        child: Row(
          children: [
            // Ảnh món ăn
            SizedBox(
              width: 120,
              height: 100,
              child: Hero(
                tag: 'food_${food.id ?? food.key}', // 🔹 giúp ảnh chuyển cảnh mượt hơn
                child: CachedNetworkImage(
                  imageUrl: food.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 300,
                  memCacheHeight: 200,
                  fadeInDuration: const Duration(milliseconds: 250),
                  fadeOutDuration: const Duration(milliseconds: 100),
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined, color: Colors.orange, size: 30),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.redAccent, size: 30),
                  ),
                  useOldImageOnUrlChange: true,
                  filterQuality: FilterQuality.low,
                ),
              ),
            ),

            // Thông tin món ăn
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      food.description.isNotEmpty
                          ? food.description
                          : 'Chưa có mô tả cho món này.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (food.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: food.tags.take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
