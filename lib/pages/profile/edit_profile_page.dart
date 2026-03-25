import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/profile_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _ageController;
  late TextEditingController _medicalNoteController;
  String? _selectedGender;
  String? _selectedBloodGroup;

  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileService>().profile;
    _nameController = TextEditingController(text: profile.name);
    _roleController = TextEditingController(text: profile.role);
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _medicalNoteController = TextEditingController(text: profile.medicalNote);
    _selectedGender = profile.gender;
    _selectedBloodGroup = profile.bloodGroup.isNotEmpty ? profile.bloodGroup : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _ageController.dispose();
    _medicalNoteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profileService = context.read<ProfileService>();
    final profile = profileService.profile;

    await profileService.saveProfile(profile.copyWith(
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup ?? '',
      medicalNote: _medicalNoteController.text.trim(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.pop(context);
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Change Profile Photo',
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: Text('Take a Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Use device camera', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ProfileService>().pickAvatarFromCamera();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              ),
              title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Select existing photo', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ProfileService>().pickAvatarFromGallery();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ProfileService>(
        builder: (_, profileService, _) {
          final profile = profileService.profile;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _showImagePicker,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          backgroundImage: profile.avatarPath != null
                              ? FileImage(File(profile.avatarPath!))
                              : null,
                          child: profile.avatarPath == null
                              ? const Icon(Icons.person_rounded, size: 48, color: AppColors.onSurfaceVariant)
                              : null,
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.onPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to change photo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Name
                _buildLabel('Full Name'),
                _buildTextField(_nameController, 'Enter your name', Icons.person_outline_rounded),

                const SizedBox(height: 20),

                // Role
                _buildLabel('Role'),
                _buildTextField(_roleController, 'e.g. Rescue Specialist, Survivor', Icons.badge_outlined),

                const SizedBox(height: 20),

                // Age
                _buildLabel('Age'),
                _buildTextField(_ageController, 'Enter your age', Icons.calendar_today_rounded,
                    keyboardType: TextInputType.number),

                const SizedBox(height: 20),

                // Gender
                _buildLabel('Gender'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGender,
                      isExpanded: true,
                      hint: Text('Select gender', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
                      items: _genders.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g, style: GoogleFonts.inter()),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Blood Group
                _buildLabel('Blood Group'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bloodGroups.map((bg) => ChoiceChip(
                    label: Text(bg),
                    selected: _selectedBloodGroup == bg,
                    onSelected: (selected) => setState(() {
                      _selectedBloodGroup = selected ? bg : null;
                    }),
                    selectedColor: AppColors.primaryFixed,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: _selectedBloodGroup == bg ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedBloodGroup == bg ? AppColors.primary : AppColors.onSurface,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: _selectedBloodGroup == bg
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.outlineVariant,
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 20),

                // Medical Note
                _buildLabel('Emergency Medical Note'),
                TextField(
                  controller: _medicalNoteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add allergies, conditions, medications, emergency contacts...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Save Profile',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
