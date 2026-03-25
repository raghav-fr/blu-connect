
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/device_model.dart';
import '../../services/bluetooth_service.dart';
import '../../services/battery_service.dart';
import '../../services/message_service.dart';
import '../../services/profile_service.dart';
import '../../services/location_service.dart';
import '../../widgets/mesh_status_badge.dart';
import '../chat/community_chat_page.dart';
import '../chat/private_chat_page.dart';
import '../../models/message_model.dart';

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothService>().startScan();
      context.read<LocationService>().getCurrentPosition();
      context.read<BatteryService>().refreshBatteryLevel();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeroStatusCard(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildNearbyDevices(),
                const SizedBox(height: 24),
                _buildCommunityChat(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.signal_cellular_alt_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'Blu Connect',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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

  Widget _buildHeroStatusCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Topographic map background
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(32),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: CustomPaint(
              painter: _TopographicPainter(),
              size: const Size(double.infinity, 180),
            ),
          ),
        ),
        // Glass overlay
        Positioned(
          left: 16,
          right: 16,
          top: 110,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Consumer2<BluetoothService, BatteryService>(
              builder: (_, ble, battery, _) => Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.hub_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ble.isBluetoothOn
                                    ? const Color(0xFFD1FAE5)
                                    : AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: ble.isBluetoothOn
                                          ? AppColors.meshActive
                                          : AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ble.isBluetoothOn ? 'Connected to Mesh' : 'Disconnected',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: ble.isBluetoothOn
                                          ? const Color(0xFF166534)
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ble.connectedDeviceCount} nearby nodes active',
                              style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          battery.isCharging ? Icons.battery_charging_full : Icons.battery_full,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          battery.batteryLabel,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.emergency_rounded,
                  label: 'SEND SOS',
                  backgroundColor: AppColors.tertiary,
                  foregroundColor: AppColors.onTertiary,
                  onTap: () {
                    // Navigate to SOS page (tab 1)
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.settings_input_antenna_rounded,
                  label: 'BROADCAST',
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunityChatPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.location_on_rounded,
                  label: 'SHARE LOCATION',
                  backgroundColor: AppColors.surfaceContainerHighest,
                  foregroundColor: AppColors.onSurface,
                  onTap: () async {
                    final loc = context.read<LocationService>();
                    await loc.getCurrentPosition();
                    if (loc.hasPosition && mounted) {
                      final profile = context.read<ProfileService>().profile;
                      await context.read<MessageService>().sendCommunityMessage(
                        senderId: profile.id,
                        senderName: profile.name.isNotEmpty ? profile.name : 'Anonymous',
                        content: '📍 Location shared: ${loc.coordinatesLabel}',
                        type: MessageType.info,
                        latitude: loc.latitude,
                        longitude: loc.longitude,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location shared to mesh network')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.flight_rounded,
                  label: 'SIGNAL DRONE',
                  backgroundColor: AppColors.surfaceContainerHighest,
                  foregroundColor: AppColors.onSurface,
                  onTap: () async {
                    final profile = context.read<ProfileService>().profile;
                    final loc = context.read<LocationService>();
                    await loc.getCurrentPosition();
                    await context.read<MessageService>().sendCommunityMessage(
                      senderId: profile.id,
                      senderName: profile.name.isNotEmpty ? profile.name : 'Anonymous',
                      content: '🚁 Drone signal sent! ${loc.hasPosition ? loc.coordinatesLabel : ""}',
                      type: MessageType.alert,
                      latitude: loc.latitude,
                      longitude: loc.longitude,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Drone signal broadcasted')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyDevices() {
    return Consumer<BluetoothService>(
      builder: (_, ble, _) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Devices',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    if (ble.isScanning)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'REAL-TIME',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filter toggle + rescan
            Row(
              children: [
                GestureDetector(
                  onTap: () => ble.toggleShowAllDevices(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ble.showAllDevices
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: ble.showAllDevices
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ble.showAllDevices ? Icons.devices : Icons.smartphone_rounded,
                          size: 14,
                          color: ble.showAllDevices ? AppColors.primary : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ble.showAllDevices ? 'All Devices' : 'Phones Only',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ble.showAllDevices ? AppColors.primary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (ble.allRawDevices.length != ble.discoveredDevices.length)
                  Text(
                    '${ble.allRawDevices.length - ble.discoveredDevices.length} filtered',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () => ble.clearAndRescan(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Rescan',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (ble.discoveredDevices.isEmpty)
              _buildEmptyDevices(ble)
            else
              ...ble.discoveredDevices.map((device) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DeviceCard(
                      device: device,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrivateChatPage(device: device),
                          ),
                        );
                      },
                    ),
                  )),
            if (ble.discoveredDevices.isEmpty && !ble.isScanning)
              Center(
                child: TextButton.icon(
                  onPressed: () => ble.startScan(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Scan for Devices'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDevices(BluetoothService ble) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              ble.isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
              size: 40,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              ble.isScanning ? 'Scanning for devices...' : 'No devices found',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (!ble.isBluetoothOn) ...[
              const SizedBox(height: 4),
              Text(
                'Enable Bluetooth to discover nearby nodes',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityChat() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CommunityChatPage()),
        );
      },
      child: Consumer<MessageService>(
        builder: (_, msgService, _) {
          final messages = msgService.communityMessages;
          final recent = messages.length > 2
              ? messages.sublist(messages.length - 2)
              : messages;

          return Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Chat',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Local mesh channels active in your sector.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFA7F3D0).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                if (recent.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'No messages yet. Tap to start broadcasting.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFD1FAE5).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )
                else
                  ...recent.map((msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6EE7B7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        msg.senderName.isNotEmpty
                                            ? msg.senderName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF064E3B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    msg.senderName,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFECFDF5),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: const Color(0xFF6EE7B7).withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                msg.content,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFFECFDF5).withValues(alpha: 0.9),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Type a message...',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFECFDF5).withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA7F3D0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF064E3B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(32),
      elevation: backgroundColor == AppColors.tertiary ? 4 : 0,
      shadowColor: backgroundColor.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: foregroundColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceInfo device;
  final VoidCallback? onTap;

  const _DeviceCard({required this.device, this.onTap});

  IconData get _deviceIcon {
    switch (device.deviceType) {
      case 'router':
        return Icons.router_rounded;
      case 'drone':
        return Icons.flight_rounded;
      default:
        return Icons.smartphone_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_deviceIcon, size: 20, color: const Color(0xFF166534)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.lastActiveLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    device.distanceLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.hopLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopographicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 8; i++) {
      paint.color = AppColors.primaryFixed.withValues(alpha: 0.3 - (i * 0.03));
      final path = Path();
      final yOffset = size.height * 0.3 + (i * 12.0);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.25, yOffset - 30 + (i * 5),
        size.width * 0.5, yOffset + 20 - (i * 3),
        size.width * 0.75, yOffset - 15 + (i * 4),
      );
      path.lineTo(size.width, yOffset + 10);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
