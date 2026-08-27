import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:greenoffice360/core/routes/app_routes.dart';
import 'package:greenoffice360/features/auth/providers/auth_provider.dart';
import 'package:greenoffice360/features/auth/screens/login_screen.dart';
import 'package:greenoffice360/features/auth/screens/registration_screen.dart';
import 'package:greenoffice360/features/auth/screens/splash_screen.dart';
import 'package:greenoffice360/features/employee/screens/employee_dashboard_screen.dart';
import 'package:greenoffice360/features/employee/screens/employee_profile_screen.dart';
import 'package:greenoffice360/features/issues/screens/issue_details_screen.dart';
import 'package:greenoffice360/features/issues/screens/issue_review_screen.dart';
import 'package:greenoffice360/features/issues/screens/issue_select_category.dart';
import 'package:greenoffice360/features/issues/screens/issue_success_screen.dart';
import 'package:greenoffice360/features/issues/controllers/issue_controller.dart';
import 'package:greenoffice360/features/issues/providers/issue_provider.dart';
import 'package:greenoffice360/features/manager/screens/manager_dashboard_screen.dart';
import 'package:greenoffice360/repositories/offline/offline_issue_repository.dart';
import 'package:greenoffice360/repositories/offline/sync_queue_repository.dart';
import 'package:greenoffice360/services/cloudinary_service.dart';
import 'package:greenoffice360/services/connectivity_service.dart';
import 'package:greenoffice360/services/local_database_service.dart';
import 'package:greenoffice360/services/sync_service.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:greenoffice360/core/theme/app_theme.dart';
import 'package:greenoffice360/features/auth/controllers/auth_controller.dart';
import 'package:greenoffice360/firebase_options.dart';
import 'package:greenoffice360/repositories/auth_repository.dart';
import 'package:greenoffice360/repositories/issue_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   final localDatabaseService = LocalDatabaseService();
  await localDatabaseService.initialize();
  final connectivityService = ConnectivityService();
  final offlineIssueRepository = OfflineIssueRepository();
  final syncQueueRepository = SyncQueueRepository();
  final syncService = SyncService(
    connectivityService: connectivityService,
    syncQueueRepository: syncQueueRepository,
    offlineIssueRepository: offlineIssueRepository,
    cloudinaryService: CloudinaryService(),
  );
  // Start automatic synchronization
  syncService.startAutoSync();
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
        Provider<CloudinaryService>(
          create: (_) => CloudinaryService(),
        ),
        ChangeNotifierProvider<IssueProvider>(
          create: (context) => IssueProvider(
            controller: IssueController(
              repository: IssueRepository(
                cloudinaryService: context.read<CloudinaryService>(),
                syncQueueRepository: syncQueueRepository,
              ),
            ),
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
      initialRoute: AppRoutes.splash,
       routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login:
            (_) => const LoginScreen(),

        AppRoutes.registration:
            (_) => const RegistrationScreen(),

        AppRoutes.issueCategory: (_) => const IssueSelectCategoryScreen(),

        AppRoutes.issueDetails: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final selectedCategory = args is String ? args : 'Water';
          return IssueDetailsScreen(selectedCategory: selectedCategory);
        },

        AppRoutes.issueReview: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>? ?? const {};
          return IssueReviewScreen(
            selectedCategory: args['selectedCategory'] ?? 'Water',
            location: args['location'] ?? 'Office Block A, Floor 4',
            description: args['description'] ?? 'No description provided.',
          );
        },

        AppRoutes.issueSuccess: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return IssueSuccessScreen(issueId: args is String ? args : null);
        },

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
