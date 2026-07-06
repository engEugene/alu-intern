import 'package:flutter/material.dart';
import '../../core/theme.dart';

final class LoadingShimmer extends StatelessWidget {
  final int itemCount;
  final double height;

  const LoadingShimmer({super.key, this.itemCount = 5, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: itemCount,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.borderCard,
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent.withAlpha(60),
            ),
          ),
        ),
      ),
    );
  }
}
