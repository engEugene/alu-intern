import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final _spaceGrotesk = GoogleFonts.spaceGrotesk().fontFamily;
  static final _nunito = GoogleFonts.nunito().fontFamily;
  static final _sourceCodePro = GoogleFonts.sourceCodePro().fontFamily;

  static TextStyle get displayLg => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 42, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.1,
  );
  static TextStyle get displayMd => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 38, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -1,
  );
  static TextStyle get displaySm => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.15,
  );
  static TextStyle get amountLg => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get headingXl => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle get headingLg => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 24, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.2,
  );
  static TextStyle get headingMd => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 22, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get headingSm => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle get headingSmLight => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 20, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleLg => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle get titleMd => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get titleSm => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 17, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle get titleSmLight => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get titleXs => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get amountSm => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get amountXs => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get sectionLabel => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textTertiary, letterSpacing: 1.2,
  );

  static TextStyle get bodyLg => TextStyle(
    fontFamily: _nunito, fontSize: 16, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodyLgLight => TextStyle(
    fontFamily: _nunito, fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodyMdLight => TextStyle(
    fontFamily: _nunito, fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodyBold => TextStyle(
    fontFamily: _nunito, fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodyMd => TextStyle(
    fontFamily: _nunito, fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static TextStyle get body => TextStyle(
    fontFamily: _nunito, fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodySm => TextStyle(
    fontFamily: _nunito, fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodySmLight => TextStyle(
    fontFamily: _nunito, fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodySmLighter => TextStyle(
    fontFamily: _nunito, fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelMd => TextStyle(
    fontFamily: _nunito, fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get labelSm => TextStyle(
    fontFamily: _nunito, fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static TextStyle get caption => TextStyle(
    fontFamily: _nunito, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static TextStyle get labelXsBold => TextStyle(
    fontFamily: _nunito, fontSize: 11, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle get labelXs => TextStyle(
    fontFamily: _nunito, fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get labelXsLight => TextStyle(
    fontFamily: _nunito, fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get buttonLg => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get buttonMd => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get buttonSm => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get buttonXs => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get numPad => TextStyle(
    fontFamily: _spaceGrotesk, fontSize: 24, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get inputHint => TextStyle(
    fontFamily: _nunito, fontSize: 15, color: AppColors.textTertiary,
  );
  static TextStyle get inputLabel => TextStyle(
    fontFamily: _nunito, fontSize: 14, color: AppColors.textSecondary,
  );
  static TextStyle get inputFloatingLabel => TextStyle(
    fontFamily: _nunito, fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );
  static TextStyle get inputError => TextStyle(
    fontFamily: _nunito, fontSize: 12, color: AppColors.error,
  );

  static TextStyle get mono => TextStyle(
    fontFamily: _sourceCodePro, fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}
