import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class SmoothToggle extends StatefulWidget {
  final void Function(int) onTabChange;
  final List<GButton> tabs;
  final int initialIndex;
  final bool isUrgent;

  const SmoothToggle({
    super.key,
    required this.onTabChange,
    required this.tabs,
    this.initialIndex = 0,
    this.isUrgent = false,
  });

  @override
  _SmoothToggleState createState() => _SmoothToggleState();
}

class _SmoothToggleState extends State<SmoothToggle> {
  late int _selectedIndex;

  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant SmoothToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selectedIndex whenever the initialIndex changes
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
    }
  }

  // Handle tab change
  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onTabChange(index);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta!;

    const double swipeThreshold = 50.0;

    if (_dragDistance > swipeThreshold) {
      if (_selectedIndex < widget.tabs.length - 1) {
        _onTabChange(_selectedIndex + 1);
      }
      _dragDistance = 0;
    } else if (_dragDistance < -swipeThreshold) {
      if (_selectedIndex > 0) {
        _onTabChange(_selectedIndex - 1);
      }
      _dragDistance = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: GNav(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 20,
          ),
          selectedIndex: _selectedIndex,
          color: Colors.grey[400],
          activeColor: widget.isUrgent && _selectedIndex == 1 ? Colors.red[800] : Colors.black,
          tabBackgroundColor:
              _selectedIndex == 1 ? (widget.isUrgent ? Colors.red[100]! : Color(0xFF00C1A2)) : Colors.grey.shade100,
          tabBorderRadius: 16,
          gap: 4,
          mainAxisAlignment: MainAxisAlignment.center,
          onTabChange: _onTabChange,
          tabs: widget.tabs,
        ),
      ),
    );
  }
}
