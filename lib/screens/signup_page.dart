import 'package:flutter/material.dart';
import 'home_page.dart';
import '../api/api_service.dart';
import '../models/signup_model.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  final _usernameFieldKey = GlobalKey<FormFieldState>();
  final _firstNameFieldKey = GlobalKey<FormFieldState>();
  final _lastNameFieldKey = GlobalKey<FormFieldState>();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _passwordFieldKey = GlobalKey<FormFieldState>();


  bool _isLoading = false;
  bool _obscurePassword = true;

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final model = SignupModel(
          userName: _usernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final result = await ApiService().signup(model);

        if (!mounted) return;

        // Remove any old banners first
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();

        if (result == null) {
          _showTopError('Server unreachable or slow network. Please try again.');
          return;
        }

        if (result) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          _showTopError('Signup failed. Please try again.');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

// Helper to show a red banner at top
  void _showTopError(String message) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade600,
        leading: const Icon(Icons.error_outline, color: Colors.white),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20.0 : 40.0,
              vertical: 20.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 600,
              ),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add_alt_1,
                            size: 40,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Join us to get started",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Username
                        TextFormField(
                          key: _usernameFieldKey,
                          controller: _usernameController,
                          decoration: _inputDecoration('Username', 'Enter your username', Icons.person_outline),
                          validator: (value) =>
                          value!.isEmpty ? 'Please enter a username' : null,
                          onChanged: (_) {
                          _usernameFieldKey.currentState?.validate();
                          },
                        ),
                        const SizedBox(height: 20),

                        // First/Middle/Last in Row for large screen
                        isSmallScreen
                            ? Column(
                          children: [
                            TextFormField(
                              key: _firstNameFieldKey,
                              controller: _firstNameController,
                              decoration: _inputDecoration('First Name', 'Enter your first name', Icons.account_circle_outlined),
                              validator: (value) =>
                              value!.isEmpty ? 'First name is required' : null,
                              onChanged: (_) {
                                 _firstNameFieldKey.currentState?.validate();
                                },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _middleNameController,
                              decoration: _inputDecoration('Middle Name (optional)', '', Icons.person_outline),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              key: _lastNameFieldKey,
                              controller: _lastNameController,
                              decoration: _inputDecoration('Last Name', 'Enter your last name', Icons.person_outline),
                              validator: (value) =>
                              value!.isEmpty ? 'Last name is required' : null,
                              onChanged: (_) {
                                _lastNameFieldKey.currentState?.validate();
                              },
                            ),
                          ],
                        )
                            : Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: _firstNameFieldKey,
                                controller: _firstNameController,
                                decoration: _inputDecoration('First Name', 'First name', Icons.account_circle_outlined),
                                validator: (value) =>
                                value!.isEmpty ? 'First name required' : null,
                                onChanged: (_) {
                                  _firstNameFieldKey.currentState?.validate();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _middleNameController,
                                decoration: _inputDecoration('Middle Name', '', Icons.person_outline),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                key: _lastNameFieldKey,
                                controller: _lastNameController,
                                decoration: _inputDecoration('Last Name', 'Last name', Icons.person_outline),
                                validator: (value) =>
                                value!.isEmpty ? 'Last name required' : null,
                                onChanged: (_) {
                                  _lastNameFieldKey.currentState?.validate();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Email
                        TextFormField(
                          key: _emailFieldKey,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction, // validate while typing
                          decoration: _inputDecoration(
                            'Email',
                            'Enter your email',
                            Icons.email_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          onChanged: (_) {
                            _lastNameFieldKey.currentState?.validate();
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password
                        TextFormField(
                          key: _passwordFieldKey,
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _inputDecoration(
                            'Password',
                            'Enter your password',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          onChanged: (_) {
                            _emailFieldKey.currentState?.validate();
                          },
                        ),

                        const SizedBox(height: 24),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: isSmallScreen ? 14 : 15,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading ? null : () => Navigator.pop(context),
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 14 : 15,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
