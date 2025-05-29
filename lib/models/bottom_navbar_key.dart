import 'package:flutter/material.dart';
import 'package:vbay/components/my_bottom_navbar.dart';

class BottomNavbarKey {
  BottomNavbarKey._privateConstructor();

  static final BottomNavbarKey instance = BottomNavbarKey._privateConstructor();

  final GlobalKey<MyBottomNavbarState> key = GlobalKey<MyBottomNavbarState>();
}