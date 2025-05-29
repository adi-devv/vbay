import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vbay/main.dart';

class BouncingText extends StatefulWidget {
  final BuildContext parentContext;

  const BouncingText({super.key, required this.parentContext});

  @override
  _BouncingTextState createState() => _BouncingTextState();
}

class _BouncingTextState extends State<BouncingText> {
  double dx = 1000;
  double dy = 1000;
  late double vx;
  late double vy;
  final random = Random();
  late String message;
  late Color boxColor;

  final List<String> messages = [
    "Looking for something? Put up a seek!",
    "This space is emptier than an 8 AM lecture… List something!",
    "No listings? Even the library has more action than this!",
    "This page is drier than the hostel mess… Post an ad already!",
    "More empty than your attendance sheet—time to fill it up!",
    "No ads? Even last-minute assignments have more submissions!",
    "Even your to-do list has more entries than this page!",
    "Couldn’t find what you need? Maybe it’s in the lost & found?",
    "Your search came up empty… just like your wallet before month-end!",
    "This page is lonelier than a group project with last-minute workers!",
    "Oops! Looks like even WiFi issues can’t explain this empty page!",
    "Nothing here… Just like the mess menu when you're actually hungry!",
    "Still searching? Maybe try summoning a wish genie instead?",
    "Not a single listing? Even exam halls have more surprises than this!",
    "Empty results? Maybe your luck is in the lost & found!",
  ];

  @override
  void initState() {
    super.initState();

    message = messages[random.nextInt(messages.length)];
    boxColor = Theme.of(widget.parentContext).colorScheme.secondary;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height * .7;
      final boxWidth = 200;
      final boxHeight = 70;

      dx = random.nextDouble() * (screenWidth - boxWidth);
      dy = random.nextDouble() * (screenHeight - boxHeight);

      vx = (random.nextBool() ? 1 : -1) * (0.5);
      vy = (random.nextBool() ? 1 : -1) * (0.5);

      Timer.periodic(Duration(milliseconds: 30), (timer) {
        if (!mounted) return;
        setState(() {
          dx += vx;
          dy += vy;

          if (dx <= 0 || dx >= screenWidth - boxWidth) {
            vx = -vx;
            boxColor = Theme.of(context).brightness == Brightness.dark ? _getRandomDarkColor() : _getRandomLightColor();
          }
          if (dy <= 0 || dy >= screenHeight - boxHeight) {
            vy = -vy;
            boxColor = Theme.of(context).brightness == Brightness.dark ? _getRandomDarkColor() : _getRandomLightColor();
          }
        });
      });
    });
  }

  Color _getRandomLightColor() {
    return Color.fromARGB(
      255,
      180 + random.nextInt(76),
      180 + random.nextInt(76),
      180 + random.nextInt(76),
    );
  }

  Color _getRandomDarkColor() {
    return Color.fromARGB(
      255,
      random.nextInt(100),
      random.nextInt(100),
      random.nextInt(100),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      body: Stack(
        children: [
          Positioned(
            left: dx,
            top: dy,
            child: Container(
              width: 200,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
