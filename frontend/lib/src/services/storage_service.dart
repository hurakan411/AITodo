import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  StorageService(this._prefs);
  final SharedPreferences _prefs;

  static const _consentKey = 'contract_consent_v1';

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool getConsentAccepted() => _prefs.getBool(_consentKey) ?? false;
  Future<void> setConsentAccepted(bool value) async => _prefs.setBool(_consentKey, value);
}

final storageServiceProvider = Provider<StorageService>((ref) => throw UnimplementedError());
