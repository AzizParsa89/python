import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import

enum AuthMode { signup, login }

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth';

  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.login;
  final Map<String, String> _authData = {
    'email': '',
    'username': '',
    'password': '',
  };
  var _isLoading = false;
  final _passwordController = TextEditingController();

  void _showErrorSnackbar(String message) {
    // Ensure context is valid before showing snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), // This message comes from the provider, potentially already localized or a generic error
        backgroundColor: Theme.of(
          context,
        ).colorScheme.error, // Using error color from theme
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;
      if (_authMode == AuthMode.login) {
        success = await authProvider.login(
          _authData['username']!,
          _authData['password']!,
        );
      } else {
        success = await authProvider.register(
          _authData['username']!,
          _authData['email']!,
          _authData['password']!,
        );
      }
      if (!success) {
        // Use a generic error message from AppLocalizations if provider message is null
        _showErrorSnackbar(
          authProvider.errorMessage ?? AppLocalizations.of(context)!.errorOccurred,
        );
      }
      // No need to navigate here, main.dart will handle it based on auth state
    } catch (error) {
      _showErrorSnackbar(AppLocalizations.of(context)!.errorOccurred); // Generic error
    }

    if (mounted) {
      // Check if the widget is still in the tree
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.login) {
      setState(() {
        _authMode = AuthMode.signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.login;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      // appBar: AppBar(title: Text(_authMode == AuthMode.login ? 'Login' : 'Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          // Ensures content is scrollable on smaller screens
          padding: const EdgeInsets.all(16.0),
          child: Card(
            // Using CardTheme from main.dart
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              width: deviceSize.width * 0.85 > 400
                  ? 400
                  : deviceSize.width * 0.85,
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      AppLocalizations.of(context)!.appTitle, // Localized
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 30,
                            color: Theme.of(context).primaryColorDark,
                          ),
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      decoration: InputDecoration( // Localized
                        labelText: AppLocalizations.of(context)!.username,
                        hintText: AppLocalizations.of(context)!.usernameHint,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          // This validation message could also be localized if needed
                          return '${AppLocalizations.of(context)!.username} cannot be empty!';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _authData['username'] = value!;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_authMode == AuthMode.signup)
                      TextFormField(
                        decoration: InputDecoration( // Localized
                          labelText: AppLocalizations.of(context)!.email,
                          hintText: AppLocalizations.of(context)!.emailHint,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty || !value.contains('@')) {
                            return 'Invalid email address!'; // Could be localized
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _authData['email'] = value!;
                        },
                      ),
                    if (_authMode == AuthMode.signup) const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration( // Localized
                        labelText: AppLocalizations.of(context)!.password,
                        hintText: AppLocalizations.of(context)!.passwordHint,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 6) {
                          return 'Password must be at least 6 characters!'; // Could be localized
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _authData['password'] = value!;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_authMode == AuthMode.signup)
                      TextFormField(
                        enabled: _authMode == AuthMode.signup,
                        decoration: InputDecoration( // Localized
                          labelText: AppLocalizations.of(context)!.confirmPassword,
                          hintText: AppLocalizations.of(context)!.confirmPasswordHint,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: _authMode == AuthMode.signup
                            ? (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match!'; // Could be localized
                                }
                                return null;
                              }
                            : null,
                      ),
                    const SizedBox(height: 30),
                    if (_isLoading)
                      CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: Text( // Localized
                            _authMode == AuthMode.login ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.register,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _switchAuthMode,
                      child: Text( // Localized
                        _authMode == AuthMode.login
                            ? AppLocalizations.of(context)!.dontHaveAnAccount
                            : AppLocalizations.of(context)!.alreadyHaveAnAccount,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
