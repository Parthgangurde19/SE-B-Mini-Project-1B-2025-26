import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../admin/screens/admin_dashboard_screen.dart';
import '../admin/screens/admin_hackathon_create_screen.dart';
import '../admin/screens/admin_hackathon_detail_screen.dart';
import '../admin/screens/admin_hackathon_edit_screen.dart';
import '../admin/screens/admin_hackathon_list_screen.dart';
import '../admin/screens/admin_login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/create_group_screen.dart';
import '../screens/hackathon/hackathon_apply_screen.dart';
import '../screens/hackathon/hackathon_list_screen.dart';
import '../screens/hackathon/my_applications_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/members/find_members_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import '../../data/models/hackathon_model.dart';

/// App router configuration
class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: _AuthStateNotifier(authProvider),
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authProvider.authState == AuthState.authenticated;
      final currentUser = authProvider.currentUser;
      final isAdminPath = state.matchedLocation.startsWith('/admin');
      final isAdminLogin = state.matchedLocation == '/admin/login';
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          isAdminLogin;

      // If still initializing, don't redirect yet
      if (authProvider.authState == AuthState.initial) {
        return null;
      }

      if (isAdminPath) {
        if (isAdminLogin) {
          return null;
        }

        if (!isLoggedIn) {
          return '/admin/login';
        }
        // Let AdminAuthGuard validate admin privileges after route enter.
        return null;
      }

      // If not logged in and not on auth page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on auth page, redirect based on role
      if (isLoggedIn && isLoggingIn) {
        // Check if profile is complete
        if (currentUser != null && !currentUser.isProfileComplete) {
          return '/profile-setup';
        }
        // Role-based redirect: admin goes to admin dashboard
        if (currentUser?.role == 'admin') {
          return '/admin/dashboard';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      // Main routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Profile routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      // Members routes
      GoRoute(
        path: '/find-members',
        name: 'find-members',
        builder: (context, state) => const FindMembersScreen(),
      ),
      // Chat routes
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final title = state.uri.queryParameters['title'] ?? 'Chat';
          final isGroupChat = state.uri.queryParameters['isGroup'] == 'true';
          return ChatScreen(
            chatId: chatId,
            title: title,
            isGroupChat: isGroupChat,
          );
        },
      ),
      // Create group route
      GoRoute(
        path: '/create-group',
        name: 'create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      // Hackathon routes
      GoRoute(
        path: '/hackathons',
        name: 'hackathons',
        builder: (context, state) => const HackathonListScreen(),
      ),
      // Student: Apply for hackathon
      GoRoute(
        path: '/hackathon-apply',
        name: 'hackathon-apply',
        builder: (context, state) {
          final hackathon = state.extra as HackathonModel;
          return HackathonApplyScreen(hackathon: hackathon);
        },
      ),
      // Student: My applications
      GoRoute(
        path: '/my-applications',
        name: 'my-applications',
        builder: (context, state) => const MyApplicationsScreen(),
      ),

      // ==================== ADMIN ROUTES ====================
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/hackathons',
        name: 'admin-hackathons',
        builder: (context, state) => const AdminHackathonListScreen(),
      ),
      GoRoute(
        path: '/admin/hackathons/add',
        name: 'admin-hackathon-add',
        builder: (context, state) => const AdminHackathonCreateScreen(),
      ),
      GoRoute(
        path: '/admin/hackathons/create',
        name: 'admin-hackathon-create',
        builder: (context, state) => const AdminHackathonCreateScreen(),
      ),
      GoRoute(
        path: '/admin/hackathons/detail',
        name: 'admin-hackathon-detail',
        builder: (context, state) {
          final hackathon = state.extra as HackathonModel;
          return AdminHackathonDetailScreen(hackathon: hackathon);
        },
      ),
      GoRoute(
        path: '/admin/hackathons/edit',
        name: 'admin-hackathon-edit',
        builder: (context, state) {
          final hackathon = state.extra as HackathonModel;
          return AdminHackathonEditScreen(hackathon: hackathon);
        },
      ),
      GoRoute(
        path: '/admin/applications',
        name: 'admin-applications',
        builder: (context, state) => const _FeatureUnavailableScreen(
          title: 'Applications',
          message: 'This flow now uses direct Google Form registrations.',
        ),
      ),
      GoRoute(
        path: '/admin/hackathon-applications/:hackathonId',
        name: 'admin-hackathon-applications',
        builder: (context, state) => const _FeatureUnavailableScreen(
          title: 'Hackathon Applications',
          message: 'This flow now uses direct Google Form registrations.',
        ),
      ),
      GoRoute(
        path: '/admin/students',
        name: 'admin-students',
        builder: (context, state) => const _FeatureUnavailableScreen(
          title: 'Students',
          message: 'Student admin list is not available in this build.',
        ),
      ),
      GoRoute(
        path: '/admin/teams',
        name: 'admin-teams',
        builder: (context, state) => const _FeatureUnavailableScreen(
          title: 'Teams',
          message: 'Team management was removed from the current flow.',
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Custom notifier for auth state changes to prevent excessive router rebuilds
class _AuthStateNotifier extends ChangeNotifier {
  final AuthProvider _authProvider;
  AuthState? _lastAuthState;

  _AuthStateNotifier(this._authProvider) {
    _lastAuthState = _authProvider.authState;
    _authProvider.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (_authProvider.authState != _lastAuthState) {
      _lastAuthState = _authProvider.authState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}

class _FeatureUnavailableScreen extends StatelessWidget {
  final String title;
  final String message;

  const _FeatureUnavailableScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
