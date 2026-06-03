import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/customer_accounts/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/riders/rider_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hybrid composition (false) is more reliable on emulators; true can show a blank beige map.
  if (Platform.isAndroid) {
    final impl = GoogleMapsFlutterPlatform.instance;
    if (impl is GoogleMapsFlutterAndroid) {
      impl.useAndroidViewSurface = false;
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Gas Delivery',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF014F5B),
            primary: const Color(0xFF014F5B),
          ),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isInitializing) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF014F5B)),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          if (authProvider.isRiderSession) {
            return const RiderHomeScreen();
          }
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
