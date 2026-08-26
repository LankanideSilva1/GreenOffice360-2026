import 'package:flutter/material.dart';
import 'package:greenoffice360/core/routes/app_routes.dart';
import 'package:greenoffice360/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/app_button.dart';
import 'login_screen.dart';

import '../widgets/registration_department_field.dart';
import '../widgets/registration_email_field.dart';
import '../widgets/registration_field.dart';
import '../widgets/registration_header.dart';
import '../widgets/registration_password_field.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String _department = 'Product & Tech';
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _employeeIdController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController = TextEditingController();

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
              child: _RegistrationContainer(
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
      child: _RegistrationForm(
        nameController: _nameController,
        emailController: _emailController,
        employeeIdController: _employeeIdController,
        passwordController: _passwordController,
        confirmPasswordController: _confirmPasswordController,
        department: _department,
        passwordVisible: _passwordVisible,
        confirmPasswordVisible: _confirmPasswordVisible,
        onDepartmentChanged: (value) {
          setState(() {
            _department = value;
          });
        },
        onPasswordVisibilityChanged: () {
          setState(() {
            _passwordVisible =
                !_passwordVisible;
          });
        },
        onConfirmPasswordVisibilityChanged: () {
          setState(() {
            _confirmPasswordVisible =
                !_confirmPasswordVisible;
          });
        },
      ),
    );
  }

  Widget _buildLandscapeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _RegistrationForm(
        nameController: _nameController,
        emailController: _emailController,
        employeeIdController: _employeeIdController,
        passwordController: _passwordController,
        confirmPasswordController:  _confirmPasswordController,
        department: _department,
        passwordVisible: _passwordVisible,
        confirmPasswordVisible: _confirmPasswordVisible,
        onDepartmentChanged: (value) {
          setState(() {
            _department = value;
          });
        },
        onPasswordVisibilityChanged: () {
          setState(() {
            _passwordVisible =
                !_passwordVisible;
          });
        },
        onConfirmPasswordVisibilityChanged: () {
          setState(() {
            _confirmPasswordVisible =
                !_confirmPasswordVisible;
          });
        },
      ),
    );
  }
}

class _RegistrationContainer extends StatelessWidget {
  final bool isLandscape;
  final Widget child;

  const _RegistrationContainer({
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

      height: isLandscape
          ? double.infinity
          : null,

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

class _RegistrationForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController employeeIdController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final String department;

  final bool passwordVisible;
  final bool confirmPasswordVisible;

  final ValueChanged<String> onDepartmentChanged;

  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onConfirmPasswordVisibilityChanged;

  const _RegistrationForm({
    required this.nameController,
    required this.emailController,
    required this.employeeIdController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.department,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.onDepartmentChanged,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmPasswordVisibilityChanged,
  });

  @override
  State<_RegistrationForm> createState() => _RegistrationFormState();

}

class _RegistrationFormState extends State<_RegistrationForm> {

  bool get hasUppercase {
  return RegExp(r'[A-Z]').hasMatch(widget.passwordController.text);
  }

  bool get hasLowercase {
    return RegExp(r'[a-z]').hasMatch(widget.passwordController.text);
  }

  bool get hasNumber {
    return RegExp(r'[0-9]').hasMatch(widget.passwordController.text);
  }

  bool get hasSpecialCharacter {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];''`~+=]').hasMatch(
      widget.passwordController.text,
    );
  }

  bool get hasMinLength {
    return widget.passwordController.text.length >= 8;
  }

  bool get isPasswordValid {
    return hasUppercase &&
        hasLowercase &&
        hasNumber &&
        hasSpecialCharacter &&
        hasMinLength;
  }

  @override
  void initState() {
    super.initState();

    widget.passwordController.addListener(_passwordChanged);
    widget.confirmPasswordController.addListener(_passwordChanged);
  }

  void _passwordChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegistrationHeader(onBack: (){
          Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
        }),

        const SizedBox(height: 22),

        const Text(
          'Join GreenOffice',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),

        const SizedBox(height: 8),

        const SizedBox(height: 22),

        RegistrationField(
          label: 'Full Name',
          hintText: 'Alex Jenkins',
          initialValue: 'Alex Jenkins',
          icon: Icons.person_outline,
          controller: widget.nameController,
        ),

        const SizedBox(height: 20),

        RegistrationEmailField(
          email: 'alex.j@greenoffice360.com',
          controller: widget.emailController,
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: RegistrationField(
                label: 'Employee ID',
                hintText: 'GO-8841',
                initialValue: 'GO-8841',
                controller: widget.employeeIdController,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: RegistrationDepartmentField(
                value: widget.department,
                onChanged: (value) {
                  if (value == null) return;
                  widget.onDepartmentChanged(value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        RegistrationPasswordField(
          label: 'Password',
          hintText: 'greenoffice12',
          initialValue: 'greenoffice12',
          isVisible: widget.passwordVisible,
          onVisibilityToggle: widget.onPasswordVisibilityChanged,
          controller: widget.passwordController,
        ),

        const SizedBox(height: 10),

        passwordRequirement(
          'At least 8 characters',
          hasMinLength,
        ),

        passwordRequirement(
          'At least one uppercase letter',
          hasUppercase,
        ),

        passwordRequirement(
          'At least one lowercase letter',
          hasLowercase,
        ),

        passwordRequirement(
          'At least one number',
          hasNumber,
        ),

        passwordRequirement(
          'At least one special character',
          hasSpecialCharacter,
        ),

        const SizedBox(height: 20),

        RegistrationPasswordField(
          label: 'Confirm Password',
          hintText: 'greenoffice9',
          initialValue: 'greenoffice9',
          isVisible: widget.confirmPasswordVisible,
          hasError: widget.confirmPasswordController.text.isNotEmpty && widget.passwordController.text != widget.confirmPasswordController.text,
          errorText: 'Passwords do not match',
          onVisibilityToggle: widget.onConfirmPasswordVisibilityChanged,
          controller: widget.confirmPasswordController,
        ),

        const SizedBox(height: 28),

        AppButton(
          text: 'Create Account',
          onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(
                context,
                listen: false,
              );

              final name = widget.nameController.text.trim();

              final email = widget.emailController.text.trim();

              final employeeId = widget.employeeIdController.text.trim();

              final password = widget.passwordController.text;

              final confirmPassword = widget.confirmPasswordController.text;

              // -------------------------
              // Validation
              // -------------------------

              if (name.isEmpty) {
                _showMessage(
                  context,
                  'Please enter your full name.',
                );
                return;
              }

              if (email.isEmpty) {
                _showMessage(
                  context,
                  'Please enter your email address.',
                );
                return;
              }

              if (employeeId.isEmpty) {
                _showMessage(
                  context,
                  'Please enter your employee ID.',
                );
                return;
              }

              if (password.isEmpty) {
                _showMessage(
                  context,
                  'Please enter a password.',
                );
                return;
              }

              if (password != confirmPassword) {
                _showMessage(
                  context,
                  'Passwords do not match.',
                );
                return;
              }

              // -------------------------
              // Register
              // -------------------------

              final success =
                  await authProvider.register(
                    email: email,
                    password: password,
                    name: name,
                    employeeId: employeeId,
                    department: widget.department,
              );

              if (!context.mounted) return;

              // -------------------------
              // Registration failed
              // -------------------------

              if (!success) {
                _showMessage(
                  context,
                  authProvider.errorMessage ??
                      'Registration failed.',
                );
                return;
              }

              // -------------------------
              // Registration successful
              // -------------------------

              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.employeeDashboard,
                (route) => false,
              );
            },
        ),

        const SizedBox(height: 18),

        const Center(
          child: Text(
            'By creating an account, you agree to our Terms and Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
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

  @override
  void dispose() {
    widget.passwordController.removeListener(_passwordChanged);
    widget.confirmPasswordController.removeListener(_passwordChanged);

    widget.passwordController.dispose();
    widget.confirmPasswordController.dispose();

    super.dispose();
  }
}

void _showMessage(
  BuildContext context,
  String message,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}
Widget passwordRequirement(String text, bool valid) {
  return Row(
    children: [
      Icon(
        valid ? Icons.check_circle : Icons.cancel,
        size: 18,
        color: valid ? AppColors.primary : AppColors.textSecondary,
      ),
      const SizedBox(width: 8),
      Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: valid ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    ],
  );
}