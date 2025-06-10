import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
        content: Text(message),
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
        _showErrorSnackbar(
          authProvider.errorMessage ?? 'Authentication failed.',
        );
      }
      // No need to navigate here, main.dart will handle it based on auth state
    } catch (error) {
      var errorMessage = 'Could not authenticate you. Please try again later.';
      _showErrorSnackbar(errorMessage);
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
                      'Typing Champ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 30, // Adjusted size
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username cannot be empty!';
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
                        decoration: const InputDecoration(
                          labelText: 'E-Mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Invalid email address!';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _authData['email'] = value!;
                        },
                      ),
                    if (_authMode == AuthMode.signup)
                      const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.length < 6) {
                          // Password length
                          return 'Password must be at least 6 characters!';
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
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: _authMode == AuthMode.signup
                            ? (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match!';
                                }
                                return null;
                              }
                            : null,
                      ),
                    const SizedBox(height: 30),
                    if (_isLoading)
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: Text(
                            _authMode == AuthMode.login ? 'LOGIN' : 'SIGN UP',
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _switchAuthMode,
                      child: Text(
                        '${_authMode == AuthMode.login ? 'Create an account' : 'Have an account? Login'}',
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
