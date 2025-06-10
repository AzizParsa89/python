import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sentence.dart';
import '../providers/typing_provider.dart';
import '../providers/auth_provider.dart'; // To get user ID

class TypingScreen extends StatefulWidget {
  static const routeName = '/typing';

  const TypingScreen({super.key});

  @override
  TypingScreenState createState() => TypingScreenState();
}

class TypingScreenState extends State<TypingScreen> {
  Sentence? _sentence;
  final TextEditingController _textController = TextEditingController();
  Timer? _timer;
  int _timeElapsedSeconds = 0;
  bool _isTypingStarted = false; // Renamed for clarity
  String _typedText = "";
  bool _isSubmitting = false; // For loading indicator on button

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sentence = ModalRoute.of(context)!.settings.arguments as Sentence?;
    if (sentence != null) {
      _sentence = sentence;
    } else {
      // Handle case where sentence is null, maybe pop back or show error
      // For now, let's assume sentence is always passed.
    }
  }

  void _startTimer() {
    if (_isTypingStarted) return; // Timer already started
    _isTypingStarted = true;
    _timeElapsedSeconds = 0; // Reset timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        // Check if widget is still in the tree
        timer.cancel();
        return;
      }
      setState(() {
        _timeElapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _isTypingStarted = false; // Ready to start again if user types
  }

  @override
  void dispose() {
    _textController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submitAttempt() async {
    if (_sentence == null || _typedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot submit empty attempt.')),
      );
      return;
    }
    _stopTimer();

    final typingProvider = Provider.of<TypingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Ensure user and user ID exist. The User model in this project has an optional ID.
    // For submission, we ideally need the backend-assigned user ID.
    // The current User model in `auth_provider` is basic: User(username: prefs.getString('username') ?? 'User');
    // This needs to be augmented with the actual user ID from the backend upon login/registration.
    // For now, we'll try to use it, but this is a point of fragility.
    final userId =
        authProvider.user?.id ??
        authProvider.token.hashCode; // Fallback, not ideal

    if (authProvider.user == null || authProvider.user!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User ID not available. Cannot submit. Please re-login.',
          ),
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    setState(() => _isSubmitting = true);

    bool success = await typingProvider.submitAttempt(
      userId: authProvider.user!.id!, // Now we assert non-null after check
      sentenceId: _sentence!.id,
      typedText: _typedText,
      timeTakenSeconds: _timeElapsedSeconds.toDouble(),
    );

    if (!mounted) return; // Check if widget is still in tree
    setState(() => _isSubmitting = false);

    if (success) {
      _textController.clear();
      _typedText = "";
      _timeElapsedSeconds = 0;
      _isTypingStarted = false; // Reset typing state

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attempt Submitted! WPM: ${typingProvider.lastAttemptResult?.wpm ?? "N/A"}, Accuracy: ${typingProvider.lastAttemptResult?.accuracy?.toStringAsFixed(1) ?? "N/A"}%',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      // Consider popping or offering to practice another sentence
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit: ${typingProvider.errorMessage ?? "Unknown error"}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  List<TextSpan> _buildSentenceSpans(String original, String typed) {
    List<TextSpan> spans = [];
    int len = original.length;
    for (int i = 0; i < len; i++) {
      Color color = Colors.grey[700]!; // Default color for untyped part
      if (i < typed.length) {
        color = (original[i] == typed[i]) ? Colors.green : Colors.red;
      }
      spans.add(
        TextSpan(
          text: original[i],
          style: TextStyle(color: color, fontSize: 18.0),
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (_sentence == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('No sentence loaded. Please go back and select one.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Practice: ${_sentence!.language.toUpperCase()} (${_sentence!.difficulty})',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: RichText(
                  text: TextSpan(
                    children: _buildSentenceSpans(_sentence!.text, _typedText),
                    // Default style for any other text in RichText
                    style: DefaultTextStyle.of(
                      context,
                    ).style.copyWith(fontSize: 18.0, height: 1.5),
                  ),
                  textAlign: TextAlign.left, // Or TextAlign.justify
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Time: $_timeElapsedSeconds s',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    // Potentially add live WPM or accuracy here if desired
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Start typing here...',
                hintText: 'The sentence will highlight as you type',
              ),
              onChanged: (text) {
                if (text.isNotEmpty && !_isTypingStarted) {
                  _startTimer();
                }
                setState(() {
                  _typedText = text;
                });
                if (text.isEmpty && _isTypingStarted) {
                  // Optionally stop or pause timer if text is deleted completely
                  // For now, timer continues once started by first char
                }
              },
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed:
                  (_typedText.isNotEmpty && _isTypingStarted && !_isSubmitting)
                  ? _submitAttempt
                  : null,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit Attempt'),
            ),
          ],
        ),
      ),
    );
  }
}
