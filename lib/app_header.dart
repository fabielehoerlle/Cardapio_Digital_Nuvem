import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final Function(String) onChangeView;

  const AppHeader({
    super.key,
    required this.onChangeView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => onChangeView('home'),
            child: const Text(
              'Dreams Doces',
              style: TextStyle(
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 1.0,
                    color: Colors.yellow,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => onChangeView('pedidos'),
          ),
        ],
      ),
    );
  }
}
