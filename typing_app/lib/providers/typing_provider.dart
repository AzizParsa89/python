import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/typing_attempt.dart';

class TypingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<TypingAttempt> _leaderboard = [];
  TypingAttempt? _lastAttemptResult;
  bool _isLoading = false;
  String? _errorMessage;

  List<TypingAttempt> get leaderboard => _leaderboard;
  TypingAttempt? get lastAttemptResult => _lastAttemptResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> submitAttempt({
    required int userId, // Or get from AuthProvider
    required int sentenceId,
    required String typedText,
    required double timeTakenSeconds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Create a temporary attempt object for submission.
    // Accuracy and WPM will be calculated and set by the backend.
    TypingAttempt attemptToSubmit = TypingAttempt(
      userId: userId,
      sentenceId: sentenceId,
      typedText: typedText,
      timeTakenSeconds: timeTakenSeconds,
    );

    try {
      _lastAttemptResult = await _apiService.submitTypingAttempt(
        attemptToSubmit,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchLeaderboard({int? sentenceId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _leaderboard = await _apiService.fetchLeaderboard(sentenceId: sentenceId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
