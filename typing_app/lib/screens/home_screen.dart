import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import
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
      // Using AppLocalizations.of(context)! for greeting
      String username = authProvider.user?.username ?? AppLocalizations.of(context)!.appTitle; // Fallback to appTitle or a generic 'User'
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '${AppLocalizations.of(context)!.greeting}, $username!', // Localized greeting
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
        return Center(child: Column(children: [CircularProgressIndicator(), const SizedBox(height: 10), Text(AppLocalizations.of(context)!.loading)]));
      }
      if (sentenceProvider.errorMessage != null) {
        return Center(
          child: Text(
            // Using generic error message, specific error from provider could be used too
            AppLocalizations.of(context)!.errorOccurred + (sentenceProvider.errorMessage != null ? ': ${sentenceProvider.errorMessage}' : ''),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        );
      }
      if (sentenceProvider.sentences.isEmpty) {
        return Center(child: Text(AppLocalizations.of(context)!.noSentences));
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonFormField<Sentence>(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.selectSentence, // Localized
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          value: sentenceProvider.currentSentence,
          isExpanded: true,
          hint: Text(AppLocalizations.of(context)!.selectSentence), // Localized
          items: sentenceProvider.sentences.map((Sentence sentence) {
            return DropdownMenuItem<Sentence>(
              value: sentence,
              child: Text( // Displaying sentence details - these are model values, not directly localizable unless the model itself has localized fields
                "${AppLocalizations.of(context)!.sentenceLanguage}: ${sentence.language.toUpperCase()} (${AppLocalizations.of(context)!.sentenceDifficulty}: ${sentence.difficulty}) - ${sentence.text.substring(0, (sentence.text.length > 20) ? 20 : sentence.text.length)}...",
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
        title: Text(AppLocalizations.of(context)!.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)), // Localized
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppLocalizations.of(context)!.profile, // Localized
            onPressed: () {
              Navigator.of(context).pushNamed(ProfileScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppLocalizations.of(context)!.logout, // Localized
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
                  title: AppLocalizations.of(context)!.startTyping, // Localized
                  subtitle: sentenceProvider.currentSentence != null
                      ? "${sentenceProvider.currentSentence!.language.toUpperCase()} (${sentenceProvider.currentSentence!.difficulty}): ${sentenceProvider.currentSentence!.text.substring(0, (sentenceProvider.currentSentence!.text.length > 25) ? 25 : sentenceProvider.currentSentence!.text.length)}..."
                      : AppLocalizations.of(context)!.selectSentence, // Localized
                  onTap: () {
                    if (sentenceProvider.currentSentence != null) {
                      Navigator.of(context).pushNamed(
                        TypingScreen.routeName,
                        arguments: sentenceProvider.currentSentence,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.selectSentence), // Localized
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 5), // Reduced space
                buildActionCard(
                  context,
                  icon: Icons.leaderboard,
                  title: AppLocalizations.of(context)!.viewLeaderboard, // Localized
                  subtitle: 'See top scores and rankings.', // This could also be localized
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
