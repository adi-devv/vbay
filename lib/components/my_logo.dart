import 'package:flutter/material.dart';

class MyLogo extends StatelessWidget {
  final double fontSize;
  final bool bold;
  final bool dark;

  const MyLogo({
    super.key,
    required this.fontSize,
    this.bold = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'VBay',
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.w600,
        color: dark ? Colors.black : Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
