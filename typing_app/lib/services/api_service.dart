import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/sentence.dart';
import '../models/typing_attempt.dart';

class ApiService {
  static const String _baseUrl =
      'http://10.0.2.2:8000/api/'; // For Android emulator
  // static const String _baseUrl = 'http://localhost:8000/api/'; // For web/desktop testing

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (includeAuth) {
      String? token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }
    return headers;
  }

  // User Authentication
  Future<Map<String, dynamic>> registerUser(
    String username,
    String? email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}register/'),
      headers: await _getHeaders(),
      body: jsonEncode(<String, String?>{
        'username': username,
        'email':
            email ??
            '', // Django User model might require email, handle accordingly
        'password': password,
      }),
    );
    if (response.statusCode == 201) {
      // Assuming backend doesn't return token on registration directly
      // Or if it does, you can parse and save it here.
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': response.body};
    }
  }

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(
        '${_baseUrl}login/',
      ), // Assuming /api/login/ or /api/token/ for token auth
      headers: await _getHeaders(),
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        // You might want to fetch user details here or confirm structure
        return {'success': true, 'token': data['token']};
      } else {
        return {'success': false, 'error': 'Token not found in response'};
      }
    } else {
      return {
        'success': false,
        'error': response.body,
        'statusCode': response.statusCode,
      };
    }
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    // Optionally, call a backend endpoint to invalidate the token
  }

  // Sentences
  Future<List<Sentence>> fetchSentences() async {
    final response = await http.get(
      Uri.parse('${_baseUrl}sentences/'),
      headers: await _getHeaders(
        includeAuth: true,
      ), // Assuming sentences require auth
    );
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(
        utf8.decode(response.bodyBytes),
      ); // Handle UTF-8 for Farsi
      return jsonResponse
          .map((sentence) => Sentence.fromJson(sentence))
          .toList();
    } else {
      throw Exception(
        'Failed to load sentences: ${response.statusCode} ${response.body}',
      );
    }
  }

  // Typing Attempts
  Future<TypingAttempt> submitTypingAttempt(TypingAttempt attempt) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}attempts/submit/'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode(attempt.toJson()),
    );
    if (response.statusCode == 201) {
      return TypingAttempt.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception(
        'Failed to submit attempt: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<TypingAttempt>> fetchLeaderboard({int? sentenceId}) async {
    String url = '${_baseUrl}leaderboard/';
    if (sentenceId != null) {
      url += '?sentence_id=$sentenceId';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(
        includeAuth: true,
      ), // Assuming leaderboard might require auth
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse
          .map((attempt) => TypingAttempt.fromJson(attempt))
          .toList();
    } else {
      throw Exception(
        'Failed to load leaderboard: ${response.statusCode} ${response.body}',
      );
    }
  }
}
