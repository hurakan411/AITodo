import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserIdService {
  static const _userIdKey = 'user_id';
  static const _uuid = Uuid();
  
  /// Get or generate user ID
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we already have a stored user ID
    String? storedId = prefs.getString(_userIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }
    
    // Generate new UUID for this user
    final userId = _uuid.v4();
    
    // Store the user ID for future use
    await prefs.setString(_userIdKey, userId);
    
    return userId;
  }
  
  /// Clear user ID (for testing or logout)
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
}
