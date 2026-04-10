import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared empty state widget — illustrated icon, heading, subtitle, optional tip.
/// Applies refactoring-ui principles: generous white space, clear hierarchy,
/// single focus point.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? hint;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustrated icon in an amber tinted circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ficsitAmber.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ficsitAmber.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 36, color: ficsitAmber),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'ShareTechMono',
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textTertiary,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
