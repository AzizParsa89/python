import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // final typingProvider = Provider.of<TypingProvider>(context); // Not needed here due to Consumer

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
        // TODO: Optionally add a filter for sentences if your API and UI support it
        // For example, a DropdownButton to select a sentence
      ),
      body: Consumer<TypingProvider>(
        // Use Consumer for more direct access and rebuild scoping
        builder: (ctx, provider, _) {
          Widget content;
          if (provider.isLoading && provider.leaderboard.isEmpty) {
            content = const Center(child: CircularProgressIndicator());
          } else if (provider.errorMessage != null) {
            content = Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${provider.errorMessage}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => provider.fetchLeaderboard(
                        sentenceId: _selectedSentenceId,
                      ),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (provider.leaderboard.isEmpty) {
            content = const Center(
              child: Text(
                'No scores yet. Be the first to set a record!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          } else {
            content = ListView.builder(
              itemCount: provider.leaderboard.length,
              itemBuilder: (ctx, i) {
                final attempt = provider.leaderboard[i];
                // TODO: Fetch User details (username) based on attempt.userId for better display
                // This would likely involve another provider or enhancing AuthProvider/User model
                String username = attempt.userId.toString(); // Placeholder
                // if (authProvider.usersCache[attempt.userId] != null) {
                //   username = authProvider.usersCache[attempt.userId].username;
                // }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: i < 3
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      'User: $username (Sentence ID: ${attempt.sentenceId})',
                    ), // Replace with actual username later
                    subtitle: Text(
                      'WPM: ${attempt.wpm ?? "N/A"} | Accuracy: ${attempt.accuracy?.toStringAsFixed(1) ?? "N/A"}% | Time: ${attempt.timeTakenSeconds.toStringAsFixed(1)}s',
                      style: const TextStyle(fontSize: 12),
                    ),
                    // isThreeLine: true, // If subtitle is too long
                    trailing: Icon(
                      Icons.emoji_events,
                      color: i < 3 ? Colors.amber : Colors.grey[400],
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
