import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider to get user details
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Using Consumer for a more targeted rebuild if user info changes while screen is visible

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.user == null) {
            // This case should ideally not be reached if ProfileScreen is only accessible when authenticated
            return const Center(
              child: Text('Not logged in or user data not available.'),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Make column wrap content
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColorLight,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).primaryColorDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileDetailRow(
                      context,
                      Icons.account_circle,
                      'Username',
                      authProvider.user!.username,
                    ),
                    const SizedBox(height: 16),
                    // Email is optional in the User model and might not be fetched from backend
                    // auth_provider.dart's User model currently only has username from prefs
                    _buildProfileDetailRow(
                      context,
                      Icons.email,
                      'Email',
                      authProvider.user!.email ?? 'Not available',
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile (Placeholder)'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Edit profile functionality is not yet implemented.',
                              ),
                            ),
                          );
                        },
                        // style: ElevatedButton.styleFrom(
                        //   primary: Theme.of(context).colorScheme.secondary, // Using accent color
                        // ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
