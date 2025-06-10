import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/sentence.dart';

class SentenceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Sentence> _sentences = [];
  Sentence? _currentSentence;
  bool _isLoading = false;
  String? _errorMessage;

  List<Sentence> get sentences => _sentences;
  Sentence? get currentSentence => _currentSentence;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSentences({String? language, String? difficulty}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _sentences = await _apiService.fetchSentences();
      // TODO: Implement filtering by language and difficulty if API supports it
      // or filter locally if all sentences are fetched.
      if (_sentences.isNotEmpty) {
        // For now, just pick the first one or a random one as current
        // In a real app, user might select or it might be based on progress
        _currentSentence = _sentences.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentSentence(Sentence sentence) {
    _currentSentence = sentence;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
