import 'package:flutter/material.dart';

class CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final double? amount;
  final VoidCallback? onTap; // Добавили

  const CategoryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    this.amount,
    this.onTap, // Добавили
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Добавили
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 28,
            backgroundColor: backgroundColor,
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          if (amount != null)
            Text(
              amount!.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
