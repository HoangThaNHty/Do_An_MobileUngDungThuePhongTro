import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../models/entities/user.dart';
import '../config/constants.dart';

// Screens — Shared
import '../views/screens/shared/splash_screen.dart';
// Screens — Auth
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/register_screen.dart';
// Screens — Tenant
import '../views/screens/tenant/home_screen.dart';
import '../views/screens/tenant/room_detail_screen.dart';
import '../views/screens/tenant/search_screen.dart';
import '../views/screens/tenant/map_screen.dart';
import '../views/screens/tenant/my_rentals_screen.dart';
import '../views/screens/tenant/my_bills_screen.dart';
import '../views/screens/tenant/contact_screen.dart';
import '../views/screens/tenant/privacy_screen.dart';
// Screens — Landlord
import '../views/screens/landlord/dashboard_screen.dart';
import '../views/screens/landlord/manage_tenants_screen.dart';
import '../views/screens/landlord/room_list_screen.dart';
import '../views/screens/landlord/create_bill_screen.dart';
import '../views/screens/landlord/create_room/step1_screen.dart';
import '../views/screens/landlord/create_room/step2_screen.dart';
import '../views/screens/landlord/create_room/step3_screen.dart';
// Scaffolds
import '../views/widgets/common/tenant_scaffold.dart';
import '../views/widgets/common/landlord_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,

    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final location = state.uri.path;

      if (isLoading) return null;
      if (location == '/splash') return null;

      final isAuthRoute = location.startsWith('/auth');

      if (!isAuthenticated) {
        return isAuthRoute ? null : '/auth/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return user?.role == UserRole.landlord ? '/landlord' : '/tenant';
      }

      if (isAuthenticated) {
        final role = user?.role;
        if (role == UserRole.landlord && location.startsWith('/tenant')) {
          return '/landlord';
        }
        if (role == UserRole.tenant && location.startsWith('/landlord')) {
          return '/tenant';
        }
      }

      return null;
    },

    routes: [
      // ─── Splash ──────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ─── Auth ────────────────────────────────
      GoRoute(
        path: '/auth',
        redirect: (context, state) {
          if (state.uri.path == '/auth' || state.uri.path == '/auth/') {
            return '/auth/login';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => LoginScreen(
              initialEmail: state.extra as String?,
            ),
          ),
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),

      // ─── Tenant Shell ─────────────────────────
      ShellRoute(
        builder: (context, state, child) => TenantScaffold(child: child),
        routes: [
          GoRoute(
            path: '/tenant',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'room/:id',
                builder: (context, state) => RoomDetailScreen(
                  roomId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'contact/:landlordId',
                    builder: (context, state) => ContactScreen(
                      landlordId: state.pathParameters['landlordId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/tenant/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/tenant/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/tenant/rentals',
            builder: (context, state) => const MyRentalsScreen(),
            routes: [
              GoRoute(
                path: 'bills/:rentalId',
                builder: (context, state) => MyBillsScreen(
                  rentalId: state.pathParameters['rentalId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/tenant/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
        ],
      ),

      // ─── Landlord Shell ───────────────────────
      ShellRoute(
        builder: (context, state, child) => LandlordScaffold(child: child),
        routes: [
          GoRoute(
            path: '/landlord',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/landlord/rooms',
            builder: (context, state) => const RoomListScreen(),
          ),
          GoRoute(
            path: '/landlord/tenants',
            builder: (context, state) => const ManageTenantsScreen(),
          ),
          GoRoute(
            path: '/landlord/create-bill',
            builder: (context, state) => const CreateBillScreen(),
          ),
          GoRoute(
            path: '/landlord/create-room',
            redirect: (context, state) {
              if (state.uri.path == '/landlord/create-room' || state.uri.path == '/landlord/create-room/') {
                return '/landlord/create-room/step1';
              }
              return null;
            },
            routes: [
              GoRoute(
                path: 'step1',
                builder: (context, state) => const Step1Screen(),
              ),
              GoRoute(
                path: 'step2',
                builder: (context, state) => const Step2Screen(),
              ),
              GoRoute(
                path: 'step3',
                builder: (context, state) => const Step3Screen(),
              ),
            ],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Trang không tìm thấy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
  );
});
