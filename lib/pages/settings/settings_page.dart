import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/settings_service.dart';
import '../../services/bluetooth_service.dart';
import '../../services/profile_service.dart';
import '../../services/emergency_service.dart';
import '../../services/wifi_direct_service.dart';
import '../../services/mesh_service.dart';
import '../../widgets/mesh_status_badge.dart';
import '../profile/profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildUserCard(context),
                const SizedBox(height: 24),
                _buildConnectivitySection(context),
                const SizedBox(height: 24),
                _buildEmergencySection(context),
                const SizedBox(height: 24),
                _buildPrivacyCard(),
                const SizedBox(height: 16),
                _buildOptimizationCard(),
                const SizedBox(height: 24),
                _buildSystemSection(context),
                const SizedBox(height: 24),
                _buildSignOutButton(context),
                const SizedBox(height: 12),
                _buildVersionInfo(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Settings',
        style: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Consumer<BluetoothService>(
            builder: (_, ble, _) => MeshStatusBadge(
              isActive: ble.isBluetoothOn && ble.connectedDeviceCount > 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context) {
    return Consumer<ProfileService>(
      builder: (_, profileService, _) {
        final profile = profileService.profile;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  backgroundImage: profile.avatarPath != null
                      ? FileImage(File(profile.avatarPath!))
                      : null,
                  child: profile.avatarPath == null
                      ? Text(
                          profile.initials,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isNotEmpty ? profile.name : 'Set up profile',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Rescuer ID: #${profile.id.substring(0, 8).toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Consumer<BluetoothService>(
                            builder: (_, ble, _) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: ble.isBluetoothOn ? const Color(0xFFD1FAE5) : AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ble.isBluetoothOn ? 'MESH ACTIVE' : 'OFFLINE',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: ble.isBluetoothOn ? const Color(0xFF166534) : AppColors.error,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'VERIFIED',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectivitySection(BuildContext context) {
    return Consumer3<SettingsService, BluetoothService, WiFiDirectService>(
      builder: (_, settings, ble, wifi, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Text(
                  'CONNECTIVITY',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Consumer<MeshService>(
                  builder: (_, mesh, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mesh.transportMode,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SettingsToggleCard(
            icon: Icons.bluetooth_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Bluetooth Mesh',
            subtitle: 'Low-energy device discovery',
            value: settings.bluetoothEnabled,
            onChanged: (v) {
              settings.setBluetoothEnabled(v);
              ble.setMeshEnabled(v);
            },
          ),
          const SizedBox(height: 8),
          _SettingsToggleCard(
            icon: Icons.wifi_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Wi-Fi Direct',
            subtitle: 'High-speed P2P (no router needed)',
            value: wifi.wifiDirectEnabled,
            onChanged: (v) {
              wifi.setWifiDirectEnabled(v);
            },
          ),
          const SizedBox(height: 8),
          _SettingsToggleCard(
            icon: Icons.radar_rounded,
            iconColor: AppColors.secondary,
            title: 'Auto-discovery',
            subtitle: 'Join nearby devices automatically',
            value: settings.autoDiscovery,
            onChanged: (v) {
              settings.setAutoDiscovery(v);
              ble.setAutoDiscovery(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (_, settings, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Text(
                  'EMERGENCY PROTOCOLS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(Icons.error_outline_rounded, size: 18, color: AppColors.tertiary),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _SettingsToggleCard(
                  icon: Icons.cell_tower_rounded,
                  iconColor: AppColors.tertiary,
                  title: 'Auto SOS',
                  subtitle: 'Broadcast on impact detection',
                  value: settings.autoSOS,
                  onChanged: settings.setAutoSOS,
                  backgroundColor: Colors.transparent,
                ),
                _SettingsToggleCard(
                  icon: Icons.wifi_tethering_rounded,
                  iconColor: AppColors.tertiary,
                  title: 'Continuous Broadcast',
                  subtitle: 'Sacrifice battery for signal reach',
                  value: settings.continuousBroadcast,
                  onChanged: settings.setContinuousBroadcast,
                  backgroundColor: Colors.transparent,
                ),
                Consumer<EmergencyService>(
                  builder: (_, emergency, _) {
                    if (!emergency.isSosTriggered) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'IMPACT DETECTED! SOS in ${emergency.countdownSeconds}s',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: emergency.cancelSos,
                            child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Consumer<SettingsService>(
      builder: (_, settings, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shield_rounded, size: 22, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Privacy Shield',
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              settings.encryptionEnabled
                  ? 'End-to-end encrypted node communication is active.'
                  : 'Encryption is disabled. Messages are not secured.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationCard() {
    return Consumer<SettingsService>(
      builder: (_, settings, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primaryFixed.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.battery_saver_rounded, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Optimization',
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'POWER SAVE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        settings.powerSaveMode ? 'On' : 'Off',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSection(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (_, settings, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'SYSTEM',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAP REGION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.mapRegion,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: ['Auto', 'North America', 'South Asia', 'Europe', 'East Asia', 'Africa']
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Row(
                                  children: [
                                    const Icon(Icons.map_rounded, size: 18, color: AppColors.onSurfaceVariant),
                                    const SizedBox(width: 10),
                                    Text(r, style: GoogleFonts.inter(fontSize: 14)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) settings.setMapRegion(v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'STORAGE USAGE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1.2 GB used', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    Text('2.0 GB Total', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Sign out logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed out of mesh network')),
          );
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Sign Out of Network'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.inverseSurface,
          foregroundColor: AppColors.primaryFixed,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Text(
        'BLU CONNECT V1.0.0 • SECURED',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsToggleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final Color? backgroundColor;

  const _SettingsToggleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
