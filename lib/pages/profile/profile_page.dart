import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/profile_service.dart';
import '../../services/bluetooth_service.dart';
import '../../models/user_profile_model.dart';
import '../../widgets/mesh_status_badge.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BLU CONNECT',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
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
      ),
      body: Consumer<ProfileService>(
        builder: (_, profileService, _) {
          final profile = profileService.profile;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              children: [
                _buildProfileHeader(context, profile),
                const SizedBox(height: 20),
                _buildBloodGroupCard(profile),
                const SizedBox(height: 20),
                _buildMedicalNote(context, profile),
                const SizedBox(height: 20),
                _buildVisibilitySection(context, profile, profileService),
                const SizedBox(height: 20),
                _buildMenuItems(context),
                const SizedBox(height: 24),
                _buildLogoutButton(context, profileService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surfaceContainerHigh,
                backgroundImage: profile.avatarPath != null
                    ? FileImage(File(profile.avatarPath!))
                    : null,
                child: profile.avatarPath == null
                    ? Text(
                        profile.initials,
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.name.isNotEmpty ? profile.name : 'Set up your profile',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (profile.role.isNotEmpty)
            Text(
              profile.role,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.meshActive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ID: ${profile.id.substring(0, 8).toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (profile.age != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${profile.age} Years',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              ),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primaryFixed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodGroupCard(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BLOOD GROUP',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColors.primaryFixed.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.bloodGroup.isNotEmpty ? profile.bloodGroup : '--',
            style: GoogleFonts.manrope(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'STATUS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColors.primaryFixed.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.meshActive,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Active Responder',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalNote(BuildContext context, UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_information_rounded, size: 20, color: AppColors.onSurface),
              const SizedBox(width: 8),
              Text(
                'Emergency Medical Note',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              profile.medicalNote.isNotEmpty
                  ? '"${profile.medicalNote}"'
                  : '"No medical notes added yet. Tap Edit Profile to add important medical information."',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_rounded, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Update Medical History',
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
    );
  }

  Widget _buildVisibilitySection(
    BuildContext context,
    UserProfile profile,
    ProfileService profileService,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Visibility',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Control who can see your medical and identity details during non-emergency periods.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _VisibilityOption(
            icon: Icons.public_rounded,
            label: 'Public',
            isSelected: profile.visibility == ProfileVisibility.public,
            onTap: () => profileService.updateVisibility(ProfileVisibility.public),
          ),
          const SizedBox(height: 8),
          _VisibilityOption(
            icon: Icons.lock_open_rounded,
            label: 'Limited Access',
            isSelected: profile.visibility == ProfileVisibility.limited,
            onTap: () => profileService.updateVisibility(ProfileVisibility.limited),
          ),
          const SizedBox(height: 8),
          _VisibilityOption(
            icon: Icons.visibility_off_rounded,
            label: 'Hidden',
            isSelected: profile.visibility == ProfileVisibility.hidden,
            onTap: () => profileService.updateVisibility(ProfileVisibility.hidden),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      children: [
        _MenuItem(
          icon: Icons.settings_rounded,
          label: 'Account Settings',
          subtitle: 'Manage authentication and global preferences',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          ),
        ),
        const SizedBox(height: 8),
        _MenuItem(
          icon: Icons.history_rounded,
          label: 'Incident Log',
          subtitle: 'Review past distress signals and responses',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _MenuItem(
          icon: Icons.shield_rounded,
          label: 'Privacy & Security',
          subtitle: 'Mesh encryption keys and data permissions',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, ProfileService profileService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Leave Blu Connect?'),
              content: const Text('Your profile data will remain on this device.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            Navigator.pop(context);
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Logout from Blu Connect'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.errorContainer,
          foregroundColor: AppColors.onErrorContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed.withValues(alpha: 0.3)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

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
                  color: AppColors.primaryFixed.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
