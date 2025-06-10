import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import
import '../providers/typing_provider.dart';
import '../models/typing_attempt.dart'; // For TypingAttempt type

class LeaderboardScreen extends StatefulWidget {
  static const routeName = '/leaderboard';

  const LeaderboardScreen({super.key});

  @override
  LeaderboardScreenState createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends State<LeaderboardScreen> {
  int? _selectedSentenceId; // Allow filtering by sentence if needed

  @override
  void initState() {
    super.initState();
    // Fetch general leaderboard initially, or based on a default/passed sentenceId
    Future.microtask(
      () => Provider.of<TypingProvider>(
        context,
        listen: false,
      ).fetchLeaderboard(sentenceId: _selectedSentenceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.leaderboardScreenTitle), // Localized
        // TODO: Optionally add a filter for sentences if your API and UI support it
      ),
      body: Consumer<TypingProvider>(
        builder: (ctx, provider, _) {
          Widget content;
          if (provider.isLoading && provider.leaderboard.isEmpty) {
            content = Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height:10), Text(localizations.loading)]));
          } else if (provider.errorMessage != null) {
            content = Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations.errorOccurred + (provider.errorMessage != null ? ': ${provider.errorMessage}' : ''), // Localized
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => provider.fetchLeaderboard(sentenceId: _selectedSentenceId),
                      label: Text(localizations.tryAgain), // Localized
                    ),
                  ],
                ),
              ),
            );
          } else if (provider.leaderboard.isEmpty) {
            content = Center(
              child: Text(
                localizations.noLeaderboardData, // Localized
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          } else {
            content = ListView.builder(
              itemCount: provider.leaderboard.length,
              itemBuilder: (ctx, i) {
                final attempt = provider.leaderboard[i];
                String username = attempt.userId.toString(); // Placeholder for User ID
                // TODO: Fetch actual username based on attempt.userId

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: i < 3 ? Theme.of(context).colorScheme.secondary : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      child: Text('${localizations.rank} ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)), // Localized Rank
                    ),
                    title: Text('${localizations.userId}: $username (${localizations.sentenceId}: ${attempt.sentenceId})'), // Localized
                    subtitle: Text(
                      '${localizations.wpm}: ${attempt.wpm ?? "N/A"} | ${localizations.accuracy}: ${attempt.accuracy?.toStringAsFixed(1) ?? "N/A"}% | ${localizations.time}: ${attempt.timeTakenSeconds.toStringAsFixed(1)}s', // Localized
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(Icons.emoji_events, color: i < 3 ? Colors.amber : Colors.grey[400]),
                    ),
                  ),
                );
              },
            );
          }
          // Wrap content with RefreshIndicator
          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchLeaderboard(sentenceId: _selectedSentenceId),
            child: content,
          );
        },
      ),
    );
  }

  // _getSafeSubstringLength is not used anymore with ListTile's default text handling
}
