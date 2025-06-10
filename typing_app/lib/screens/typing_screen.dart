import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import
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
    final localizations = AppLocalizations.of(context)!; // For easier access

    if (_sentence == null || _typedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.errorOccurred)), // Example, could be more specific
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
        SnackBar(
          content: Text(localizations.errorOccurred), // Example generic error
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
            // Using string interpolation with localized fields
            localizations.attemptSubmitted + '\n' +
            localizations.wpm + ': ${typingProvider.lastAttemptResult?.wpm ?? "N/A"}\n' +
            localizations.accuracy + ': ${typingProvider.lastAttemptResult?.accuracy?.toStringAsFixed(1) ?? "N/A"}%'
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
            localizations.errorOccurred + (typingProvider.errorMessage != null ? ': ${typingProvider.errorMessage}' : '')
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
    final localizations = AppLocalizations.of(context)!;

    if (_sentence == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.errorOccurred)),
        body: Center(
          child: Text(localizations.noSentences), // Or a more specific error
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text( // Localized title
          '${localizations.typingScreenTitle}: ${_sentence!.language.toUpperCase()} (${_sentence!.difficulty})'
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
                      '${localizations.time}: $_timeElapsedSeconds s', // Localized
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
              decoration: InputDecoration( // Localized
                border: const OutlineInputBorder(),
                labelText: localizations.startTyping, // Placeholder, could be more specific like "Type here"
                hintText: 'The sentence will highlight as you type', // This hint can also be localized
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
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary), // Use onPrimary for ElevatedButton
                      ),
                    )
                  : Text(localizations.submit), // Localized
            ),
          ],
        ),
      ),
    );
  }
}
