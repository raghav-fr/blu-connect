import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class QuickMessageTemplates extends StatelessWidget {
  final Function(String) onSelect;

  const QuickMessageTemplates({super.key, required this.onSelect});

  static const List<Map<String, String>> _templates = [
    {'emoji': '🤕', 'text': 'I am injured and need medical help'},
    {'emoji': '🏚️', 'text': 'Trapped under debris, need immediate rescue'},
    {'emoji': '💧', 'text': 'Need food and water urgently'},
    {'emoji': '👨‍👩‍👧‍👦', 'text': 'Family of multiple people stranded here'},
    {'emoji': '🔥', 'text': 'Fire hazard in the area, avoid this location'},
    {'emoji': '🌊', 'text': 'Flood waters rising, need evacuation'},
    {'emoji': '✅', 'text': 'I am safe. No assistance needed'},
    {'emoji': '🏥', 'text': 'Need medication urgently'},
    {'emoji': '👶', 'text': 'Children present, need priority rescue'},
    {'emoji': '🛣️', 'text': 'Road is blocked, take alternate route'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Emergency Messages',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to send instantly',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _templates.length,
              itemBuilder: (_, i) {
                final t = _templates[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => onSelect('${t['emoji']} ${t['text']}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Text(t['emoji']!, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t['text']!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
