import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:greenoffice360/core/routes/app_routes.dart';
import 'package:greenoffice360/features/auth/providers/auth_provider.dart';
import 'package:greenoffice360/features/auth/screens/login_screen.dart';
import 'package:greenoffice360/features/auth/screens/registration_screen.dart';
import 'package:greenoffice360/features/auth/screens/splash_screen.dart';
import 'package:greenoffice360/features/employee/screens/employee_dashboard_screen.dart';
import 'package:greenoffice360/features/employee/screens/employee_profile_screen.dart';
import 'package:greenoffice360/features/manager/screens/manager_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:greenoffice360/core/theme/app_theme.dart';
import 'package:greenoffice360/features/auth/controllers/auth_controller.dart';
import 'package:greenoffice360/firebase_options.dart';
import 'package:greenoffice360/repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final authRepository = AuthRepository();
  final authController = AuthController(
    repository: authRepository
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            controller: authController,
          ),
        ),
      ],
      child: const GreenOfficeApp(),
    ),
  );
}

class GreenOfficeApp extends StatelessWidget {
  const GreenOfficeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenOffice 360',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // home: const SplashScreen(),
      initialRoute: AppRoutes.splash,
       routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login:
            (_) => const LoginScreen(),

        AppRoutes.registration:
            (_) => const RegistrationScreen(),

        AppRoutes.employeeDashboard:
            (_) => const EmployeeDashboardScreen(),

        AppRoutes.employeeProfile:
            (_) => const EmployeeProfileScreen(),

        AppRoutes.managerDashboard:
            (_) => const ManagerDashboardScreen(),

        // AppRoutes.adminDashboard:
        //     (_) => const AdminDashboardScreen(),
      },
    );
  }
}
