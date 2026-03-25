import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/location_service.dart';
import '../../services/profile_service.dart';
import '../../services/message_service.dart';
import '../../services/mesh_service.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/mesh_status_badge.dart';
import '../../models/message_model.dart';

class EmergencySOSPage extends StatefulWidget {
  const EmergencySOSPage({super.key});

  @override
  State<EmergencySOSPage> createState() => _EmergencySOSPageState();
}

class _EmergencySOSPageState extends State<EmergencySOSPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isSending = false;
  bool _continuousPing = false;
  Timer? _pingTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Get location on page open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationService>().getCurrentPosition();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendSOS() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    final loc = context.read<LocationService>();
    final profile = context.read<ProfileService>().profile;

    // Get fresh GPS coordinates
    await loc.getCurrentPosition();

    final msgService = context.read<MessageService>();
    await msgService.sendCommunityMessage(
      senderId: profile.id,
      senderName: profile.name.isNotEmpty ? profile.name : 'Unknown',
      content: '🆘 EMERGENCY SOS\n'
          'Name: ${profile.name}\n'
          'Blood Group: ${profile.bloodGroup}\n'
          'Medical: ${profile.medicalNote}\n'
          'Location: ${loc.coordinatesLabel}',
      type: MessageType.sos,
      latitude: loc.latitude,
      longitude: loc.longitude,
    );

    setState(() {
      _isSending = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🆘 SOS broadcasted to all nearby nodes'),
          backgroundColor: AppColors.tertiary,
        ),
      );
    }
  }

  void _toggleContinuousPing(bool value) {
    setState(() => _continuousPing = value);

    if (value) {
      final loc = context.read<LocationService>();
      loc.startContinuousTracking();

      _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _sendSOS();
      });
    } else {
      _pingTimer?.cancel();
      _pingTimer = null;
      context.read<LocationService>().stopContinuousTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Blu Connect',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            _buildSOSButton(),
            const SizedBox(height: 16),
            Text(
              'Instantly broadcast your emergency\nsignal to all nearby nodes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildCoordinatesCard(),
            const SizedBox(height: 16),
            _buildIdentityCard(),
            const SizedBox(height: 16),
            _buildStatusRow(),
            const SizedBox(height: 16),
            _buildDisclaimerCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onLongPress: _sendSOS,
      onTap: _sendSOS,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, child) {
          final scale = 1.0 + (_pulseController.value * 0.03);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tertiary.withValues(alpha: 0.15 + _pulseController.value * 0.1),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: AppColors.tertiary.withValues(alpha: 0.2),
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emergency_rounded,
                    size: 56,
                    color: _isSending ? AppColors.error : AppColors.tertiary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ONE-TAP SOS',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tertiary,
                    ),
                  ),
                  Text(
                    _isSending ? 'SENDING...' : 'PRESS AND HOLD',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiary.withValues(alpha: 0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    return Consumer<LocationService>(
      builder: (_, loc, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE COORDINATES',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.hasPosition
                        ? '${loc.currentPosition!.latitude.abs().toStringAsFixed(4)}° ${loc.currentPosition!.latitude >= 0 ? "N" : "S"}'
                        : 'Acquiring...',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (loc.hasPosition)
                    Text(
                      '${loc.currentPosition!.longitude.abs().toStringAsFixed(4)}° ${loc.currentPosition!.longitude >= 0 ? "E" : "W"}',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (loc.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        loc.error!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (loc.isTracking)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.gps_fixed_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Consumer<ProfileService>(
      builder: (_, profileService, _) {
        final profile = profileService.profile;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_rounded, size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          'BROADCAST IDENTITY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            profile.visibilityLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
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
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name.isNotEmpty ? profile.name : 'Set up profile',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (profile.bloodGroup.isNotEmpty)
                              Text(
                                'Medical ID: Type ${profile.bloodGroup}${profile.medicalNote.isNotEmpty ? " | ${profile.medicalNote.substring(0, profile.medicalNote.length.clamp(0, 20))}" : ""}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cell_tower_rounded, size: 24, color: AppColors.onSurface),
                const SizedBox(height: 8),
                Text(
                  'CONTINUOUS\nPING',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _continuousPing ? 'Active' : 'Off',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Switch(
                      value: _continuousPing,
                      onChanged: _toggleContinuousPing,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer<MeshService>(
            builder: (_, mesh, _) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sync_rounded, size: 24, color: AppColors.onSurface),
                  const SizedBox(height: 8),
                  Text(
                    'LAST SYNC',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mesh.lastSyncLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Signal Strong',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
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

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 24, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use with Discretion',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Triggering an SOS sends your profile and location to all active nodes within 15km. Misuse may result in restricted network access.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
