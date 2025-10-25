// lib/widgets/app_topbar.dart
import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final VoidCallback onCameraPressed;
  final ValueChanged<String>? onChanged;

  const AppTopBar({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.onCameraPressed,
    this.onChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.orange,
      elevation: 0,
      titleSpacing: 10,
      title: Row(
        children: [
          _buildIconButton(Icons.menu, 'Mở menu'),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: searchController,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 14, height: 1.2),
                decoration: InputDecoration(
                  hintText: 'Tìm món ăn...',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 0,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.orange),
                    onPressed: onSearch,
                  ),
                ),
                onChanged: onChanged,
                onSubmitted: (_) => onSearch(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildIconButton(Icons.camera_alt, 'Chụp/Chọn ảnh',
              onPressed: onCameraPressed),
          const SizedBox(width: 10),
          _buildIconButton(Icons.apps, 'Danh mục'),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip,
      {VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed ?? () => debugPrint('Button pressed: $tooltip'),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.orange, size: 24),
      ),
    );
  }
}
