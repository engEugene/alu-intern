import 'package:flutter/material.dart';
import '../../core/theme.dart';

final class LoadingShimmer extends StatelessWidget {
  final int itemCount;
  final double height;

  const LoadingShimmer({super.key, this.itemCount = 5, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.surface,
            AppColors.card,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: ListView.builder(
        padding: AppSpacing.screenPadding,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white, // replaced by the shader
              borderRadius: AppRadius.borderCard,
            ),
          ),
        ),
      ),
    );
  }
}