import 'dart:convert';

import 'package:dio/dio.dart';
import 'api_service.dart';
import 'local_storage.dart';
import '../config/constants.dart';

class AuthService {
  final ApiService _apiService;
  final LocalStorage _localStorage;

  AuthService(this._apiService, this._localStorage);

  Future<AuthResponse> loginCrew(String username, String password) async {
    // Mock authentication untuk development
    if (AppConstants.useMockAuth) {
      final finalUsername =
          username.trim().isEmpty ? 'crew001' : username.trim();
      final mockResponse = AuthResponse(
        accessToken:
            'mock_access_token_crew_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_refresh_token_crew',
        role: 'crew',
        userData: {
          'id': 'crew_001',
          'username': finalUsername,
          'nama': finalUsername == 'crew001' ? 'Crew Test User' : finalUsername,
          'email': '$finalUsername@depoair.local',
        },
      );
      await _saveSession(mockResponse);
      return mockResponse;
    }

    final response = await _apiService.loginCrew(
      LoginRequest(username: username, password: password),
    );
    await _saveSession(response);
    return response;
  }

  Future<AuthResponse> loginManager(String username, String password) async {
    // Mock authentication untuk development
    if (AppConstants.useMockAuth) {
      final finalEmail =
          username.trim().isEmpty ? 'manager@depoair.com' : username.trim();
      final displayName =
          finalEmail.contains('@') ? finalEmail.split('@')[0] : finalEmail;
      final mockResponse = AuthResponse(
        accessToken:
            'mock_access_token_manager_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_refresh_token_manager',
        role: 'manager',
        userData: {
          'id': 'manager_001',
          'email': finalEmail,
          'nama': finalEmail == 'manager@depoair.com'
              ? 'Manager Test User'
              : displayName,
          'username': displayName,
        },
      );
      await _saveSession(mockResponse);
      return mockResponse;
    }

    final response = await _apiService.loginManager(
      LoginRequest(username: username, password: password),
    );
    await _saveSession(response);
    return response;
  }

  Future<void> logout() async {
    try {
      if (!AppConstants.useMockAuth) {
        final refreshToken =
            await _localStorage.getSecure(AppConstants.keyRefreshToken);
        await _apiService.logout(refreshToken: refreshToken);
      }
    } catch (_) {
      // Tetap lanjut logout lokal meski API error
    } finally {
      await _clearSession();
    }
  }

  Future<AuthResponse?> tryRefreshToken() async {
    final refreshToken =
        await _localStorage.getSecure(AppConstants.keyRefreshToken);
    if (refreshToken == null) return null;

    try {
      // Mock refresh untuk development
      if (AppConstants.useMockAuth &&
          refreshToken.startsWith('mock_refresh_token')) {
        return null; // Mock doesn't need refresh
      }

      final response = await _apiService.refreshToken(
        RefreshTokenRequest(refreshToken: refreshToken),
      );
      await _saveSession(response);
      return response;
    } on DioException {
      await _clearSession();
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _localStorage.getSecure(AppConstants.keyAccessToken);
    return token != null;
  }

  Future<String?> getCurrentRole() async {
    return _localStorage.getString(AppConstants.keyUserRole);
  }

  Future<String?> getCurrentUserId() async {
    return _localStorage.getString(AppConstants.keyUserId);
  }

  Future<Map<String, dynamic>?> getSavedUserData() async {
    final raw = _localStorage.getString(AppConstants.userDataKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSession(AuthResponse response) async {
    await Future.wait([
      _localStorage.setSecure(
          AppConstants.keyAccessToken, response.accessToken),
      _localStorage.setSecure(
          AppConstants.keyRefreshToken, response.refreshToken),
      _localStorage.setString(AppConstants.keyUserRole, response.role),
      _localStorage.setString(
          AppConstants.keyUserId, response.userData['id']?.toString() ?? ''),
      _localStorage.setString(
          AppConstants.userDataKey, jsonEncode(response.userData)),
    ]);
  }

  Future<void> _clearSession() async {
    await Future.wait([
      _localStorage.removeSecure(AppConstants.keyAccessToken),
      _localStorage.removeSecure(AppConstants.keyRefreshToken),
      _localStorage.remove(AppConstants.keyUserRole),
      _localStorage.remove(AppConstants.keyUserId),
      _localStorage.remove(AppConstants.userDataKey),
    ]);
  }
}
