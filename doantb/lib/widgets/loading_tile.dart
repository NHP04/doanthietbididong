// lib/widgets/loading_tile.dart
import 'package:flutter/material.dart';

class LoadingTile extends StatelessWidget {
  const LoadingTile({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
