import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/bluetooth_service.dart';
import 'services/location_service.dart';
import 'services/battery_service.dart';
import 'services/profile_service.dart';
import 'services/message_service.dart';
import 'services/settings_service.dart';
import 'services/mesh_service.dart';
import 'services/emergency_service.dart';
import 'services/wifi_direct_service.dart';
import 'pages/dashboard/main_dashboard_page.dart';
import 'pages/sos/emergency_sos_page.dart';
import 'pages/settings/settings_page.dart';

import 'pages/profile/edit_profile_page.dart';
import 'widgets/app_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const BluConnectApp());
}

class BluConnectApp extends StatelessWidget {
  const BluConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProxyProvider2<ProfileService, SettingsService, BluetoothService>(
          create: (ctx) => BluetoothService(
            profileService: ctx.read<ProfileService>(),
            settingsService: ctx.read<SettingsService>(),
          ),
          update: (ctx, profile, settings, bluetooth) =>
              bluetooth ?? BluetoothService(profileService: profile, settingsService: settings),
        ),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => BatteryService()),
        ChangeNotifierProvider(create: (_) => MessageService()),
        ChangeNotifierProxyProvider2<ProfileService, SettingsService, WiFiDirectService>(
          create: (ctx) => WiFiDirectService(
            profileService: ctx.read<ProfileService>(),
            settingsService: ctx.read<SettingsService>(),
          ),
          update: (ctx, profile, settings, previous) =>
              previous ?? WiFiDirectService(profileService: profile, settingsService: settings),
        ),
        ChangeNotifierProxyProvider3<BluetoothService, WiFiDirectService, MessageService, MeshService>(
          create: (ctx) => MeshService(
            bleService: ctx.read<BluetoothService>(),
            wifiService: ctx.read<WiFiDirectService>(),
            messageService: ctx.read<MessageService>(),
          ),
          update: (ctx, ble, wifi, message, previous) {
            previous?.updateWifiService(wifi);
            return previous ?? MeshService(bleService: ble, wifiService: wifi, messageService: message);
          },
        ),
        ChangeNotifierProxyProvider4<SettingsService, LocationService,
            MessageService, ProfileService, EmergencyService>(
          create: (ctx) => EmergencyService(
            settings: ctx.read<SettingsService>(),
            location: ctx.read<LocationService>(),
            messageService: ctx.read<MessageService>(),
            profile: ctx.read<ProfileService>(),
          ),
          update: (ctx, settings, location, message, profile, previous) =>
              previous ??
              EmergencyService(
                settings: settings,
                location: location,
                messageService: message,
                profile: profile,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'Blu Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Check if profile needs setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileService = context.read<ProfileService>();
      if (profileService.isLoaded && !profileService.isProfileSetup) {
        // Show edit profile on first launch
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfilePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to profile to re-check after load
    context.watch<ProfileService>();

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              MainDashboardPage(),
              EmergencySOSPage(),
              SettingsPage(),
            ],
          ),
          AppNavigation(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
    );
  }
}
