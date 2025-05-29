import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vbay/models/bottom_navbar_key.dart';
import 'package:vbay/services/data/chat_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/models/product.dart';

class ChatProvider extends ChangeNotifier {
  bool _inChat = false;
  String? _chatWithID;

  bool get inChat => _inChat;

  String? get chatWithID => _chatWithID;

  void setChatData({String? chatWithID}) {
    if (chatWithID != null) {
      _inChat = true;
    } else {
      _inChat = false;
    }
    _chatWithID = chatWithID;
  }

  void reset(){
    _inChat = false;
    _chatWithID = null;
  }
}
