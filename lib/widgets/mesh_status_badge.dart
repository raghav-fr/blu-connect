import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class MeshStatusBadge extends StatelessWidget {
  final bool isActive;

  const MeshStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFECFDF5).withValues(alpha: 0.9)
            : AppColors.errorContainer.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isActive
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.meshActive : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'MESH ACTIVE' : 'NO MESH',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isActive
                  ? const Color(0xFF166534)
                  : AppColors.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
