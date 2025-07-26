// lib/services/mistake_restoration_service.dart
// Service to track mistake restoration state globally

import 'package:flutter/foundation.dart';

class MistakeRestorationService extends ChangeNotifier {
  static final MistakeRestorationService _instance =
      MistakeRestorationService._internal();
  factory MistakeRestorationService() => _instance;
  MistakeRestorationService._internal();

  bool _isRestoring = false;
  String _restorationMessage = '';

  bool get isRestoring => _isRestoring;
  String get restorationMessage => _restorationMessage;

  void startRestoration(String message) {
    _isRestoring = true;
    _restorationMessage = message;
    notifyListeners();
  }

  void completeRestoration() {
    _isRestoring = false;
    _restorationMessage = '';
    notifyListeners();
  }
}
