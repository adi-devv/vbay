import 'package:flutter/material.dart';

class TealButton extends StatefulWidget {
  final Future<void> Function()? onTap;
  final String text;

  const TealButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  _TealButtonState createState() => _TealButtonState();
}

class _TealButtonState extends State<TealButton> {
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isButtonPressed
          ? null
          : () async {
              setState(() {
                _isButtonPressed = true;
              });
              if (widget.onTap != null) {
                await widget.onTap!();
              }
              setState(() {
                _isButtonPressed = false;
              });
            },
      child: AbsorbPointer(
        absorbing: _isButtonPressed,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF00C1A2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          width: 140,
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
