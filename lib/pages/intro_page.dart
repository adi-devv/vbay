import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vbay/components/my_logo.dart';
import 'dart:math';

class IntroPage extends StatefulWidget {
  final bool signedIn;
  final VoidCallback? onTap;

  const IntroPage({super.key, this.signedIn = false, this.onTap});

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  final ValueNotifier<double> _scale = ValueNotifier(1.0);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(begin: const Offset(0, 2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _controller.forward();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    precacheImage(AssetImage("assets/default33.png"), context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scale.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scale.value = 1.1;
  }

  void _onTapUp(TapUpDetails details) {
    _scale.value = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFB3E5FC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox.expand(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/default33.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 112),
                          MyLogo(fontSize: 56, dark: true),
                          const SizedBox(height: 4),
                          Text(
                            "Your Campus Marketplace \nSwipe, Buy, Sell!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withValues(alpha: .5),
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _offsetAnimation,
                          child: GestureDetector(
                            onTap: widget.onTap,
                            onTapDown: _onTapDown,
                            onTapUp: _onTapUp,
                            child: ValueListenableBuilder<double>(
                              valueListenable: _scale,
                              builder: (context, scale, child) {
                                return AnimatedScale(
                                  scale: scale,
                                  duration: const Duration(milliseconds: 150),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.signedIn
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(widget.signedIn ? 12 : 30),
                                      boxShadow: widget.signedIn
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                    ),
                                    padding: widget.signedIn
                                        ? const EdgeInsets.all(16)
                                        : const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                                    child: widget.signedIn
                                        ? const Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'assets/google.png',
                                                height: 20,
                                                width: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Continue with Google",
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.inversePrimary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
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
