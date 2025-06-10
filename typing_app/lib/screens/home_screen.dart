import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sentence_provider.dart';
import './typing_screen.dart';
import './leaderboard_screen.dart';
import './profile_screen.dart'; // Added for profile screen navigation

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch sentences when the home screen is initialized
    // Use listen: false in initState if you're calling a method that might trigger rebuilds
    // However, for fetching initial data, it's common to do it here.
    // Ensure the provider method handles loading states appropriately.
    Future.microtask(
      () => Provider.of<SentenceProvider>(
        context,
        listen: false,
      ).fetchSentences(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sentenceProvider = Provider.of<SentenceProvider>(
      context,
      listen: true,
    ); // listen: true to rebuild on sentence list changes

    Widget buildGreeting(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Welcome, ${authProvider.user?.username ?? 'Typist'}!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).primaryColorDark,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    Widget buildActionCard(
      BuildContext context, {
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Card(
        // elevation is handled by CardTheme in main.dart
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0), // from CardTheme
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, size: 40, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildSentenceSelector(BuildContext context) {
      if (sentenceProvider.isLoading && sentenceProvider.sentences.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (sentenceProvider.errorMessage != null) {
        return Center(
          child: Text(
            'Error: ${sentenceProvider.errorMessage}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      }
      if (sentenceProvider.sentences.isEmpty) {
        return const Center(child: Text('No sentences available.'));
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonFormField<Sentence>(
          decoration: InputDecoration(
            labelText: 'Select a Sentence',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          value: sentenceProvider.currentSentence,
          isExpanded: true,
          hint: const Text("Choose a sentence to practice"),
          items: sentenceProvider.sentences.map((Sentence sentence) {
            return DropdownMenuItem<Sentence>(
              value: sentence,
              child: Text(
                "${sentence.language.toUpperCase()} (${sentence.difficulty}): ${sentence.text.substring(0, (sentence.text.length > 40) ? 40 : sentence.text.length)}...",
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (Sentence? newValue) {
            if (newValue != null) {
              sentenceProvider.setCurrentSentence(newValue);
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Typing Champ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ), // Using AppBarTheme
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).pushNamed(ProfileScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => sentenceProvider.fetchSentences(),
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Make scrollable even if content is small for RefreshIndicator
          child: Padding(
            padding: const EdgeInsets.all(
              8.0,
            ), // Overall padding for the content body
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                buildGreeting(context),
                buildSentenceSelector(context),
                const SizedBox(height: 10),
                buildActionCard(
                  context,
                  icon: Icons.keyboard,
                  title: 'Start Typing',
                  subtitle: sentenceProvider.currentSentence != null
                      ? "${sentenceProvider.currentSentence!.language.toUpperCase()} (${sentenceProvider.currentSentence!.difficulty}): ${sentenceProvider.currentSentence!.text.substring(0, (sentenceProvider.currentSentence!.text.length > 25) ? 25 : sentenceProvider.currentSentence!.text.length)}..."
                      : 'Select a sentence above to start practicing.',
                  onTap: () {
                    if (sentenceProvider.currentSentence != null) {
                      Navigator.of(context).pushNamed(
                        TypingScreen.routeName,
                        arguments: sentenceProvider.currentSentence,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a sentence first!'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 5), // Reduced space
                buildActionCard(
                  context,
                  icon: Icons.leaderboard,
                  title: 'View Leaderboard',
                  subtitle: 'See top scores and rankings.',
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(LeaderboardScreen.routeName);
                  },
                ),
                // You can add more cards here for other features
              ],
            ),
          ),
        ),
      ),
    );
  }
}
