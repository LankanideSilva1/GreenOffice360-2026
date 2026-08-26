import 'package:flutter/material.dart';
import 'package:greenoffice360/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:greenoffice360/core/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/app_button.dart';

import '../widgets/registration_email_field.dart';
import '../widgets/registration_password_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _passwordVisible = false;
  final TextEditingController _emailController =
    TextEditingController();

final TextEditingController _passwordController =
    TextEditingController();

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape =
            orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: _LoginContainer(
                isLandscape: isLandscape,
                child: _buildContent(isLandscape),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isLandscape) {
    if (isLandscape) {
      return _buildLandscapeContent();
    }

    return _buildPortraitContent();
  }

  Widget _buildPortraitContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        20,
      ),
      child: _LoginForm(
        passwordVisible: _passwordVisible,
        onPasswordVisibilityChanged: () {
          setState(() {
            _passwordVisible = !_passwordVisible;
          });
        },
        emailController: _emailController,
        passwordController: _passwordController,
      ),
    );
  }

  Widget _buildLandscapeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _LoginForm(
        passwordVisible: _passwordVisible,
        onPasswordVisibilityChanged: () {
          setState(() {
            _passwordVisible = !_passwordVisible;
          });
        },
        emailController: _emailController,
        passwordController: _passwordController,
      ),
    );
  }
}

class _LoginContainer extends StatelessWidget {
  final bool isLandscape;
  final Widget child;

  const _LoginContainer({
    required this.isLandscape,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isLandscape
          ? double.infinity
          : MediaQuery.of(context).size.width > 430
              ? 402
              : MediaQuery.of(context).size.width * 0.92,
      constraints: BoxConstraints(
        maxWidth: isLandscape ? 900 : 430,
      ),
      height: isLandscape ? double.infinity : null,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.loginBorder,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

class _LoginForm extends StatelessWidget {
  final bool passwordVisible;
  final VoidCallback onPasswordVisibilityChanged;

  final TextEditingController emailController;
  final TextEditingController passwordController;

  const _LoginForm({
    required this.passwordVisible,
    required this.onPasswordVisibilityChanged,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const RegistrationHeader(),

        const SizedBox(height: 22),

        const Text(
          'Welcome back',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Enter your credentials to access your '
          'organization\'s green dashboard.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 28),

        RegistrationEmailField(
          email: emailController.text.isEmpty
              ? 'alex.jenkins@greenoffice.com'
              : emailController.text,
          controller: emailController,
        ),

        const SizedBox(height: 20),

        RegistrationPasswordField(
          label: 'Password',
          hintText: 'supersecret',
          initialValue: passwordController.text,
          isVisible: passwordVisible,
          onVisibilityToggle: onPasswordVisibilityChanged,
          controller: passwordController,
        ),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              final email =
                  emailController.text.trim();

              if (email.isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter your email address.',
                    ),
                  ),
                );

                return;
              }

              try {
                await authProvider.resetPassword(
                  email: email,
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password reset email sent.',
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to reset password.',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        AppButton(
          text: authProvider.isLoading
              ? 'Logging in...'
              : 'Login',
          onPressed: authProvider.isLoading
              ? null
              : () async {
                  final email = emailController.text.trim();

                  final password = passwordController.text;

                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter your email address.',
                        ),
                      ),
                    );

                    return;
                  }

                  if (password.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter your password.',
                        ),
                      ),
                    );

                    return;
                  }

                  final success =
                      await authProvider.login(
                    email: email,
                    password: password,
                  );

                  if (!context.mounted) return;

                  if (!success) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          authProvider.errorMessage ??
                              'Login failed.',
                        ),
                      ),
                    );

                    return;
                  }

                  switch (authProvider.role) {
                    // case 'admin':
                    //   Navigator.pushNamedAndRemoveUntil(
                    //     context,
                    //     AppRoutes.adminDashboard,
                    //     (route) => false,
                    //   );
                    //   break;

                    case 'manager':
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.managerDashboard,
                        (route) => false,
                      );
                      break;

                    case 'employee':
                    default:
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.employeeDashboard,
                        (route) => false,
                      );
                      break;
                  }
                },
        ),

        const SizedBox(height: 18),

        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.registration,
              );
            },
            child: const Text.rich(
              TextSpan(
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: 'New to GreenOffice? ',
                  ),
                  TextSpan(
                    text: 'Create account',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        Container(
          height: 1,
          color: AppColors.loginDivider,
        ),
      ],
    );
  }
}