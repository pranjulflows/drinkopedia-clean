import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColorPalette {
  final MaterialColor primarySwatch;
  final MaterialColor darkSwatch;
  final MaterialColor secondarySwatch;
  final MaterialColor additionalSwatch1;
  final MaterialColor additionalSwatch2;
  final MaterialColor yellowSwatch3;
  final MaterialColor purpleSwatch;
  final MaterialColor greenSwatch;
  final MaterialColor redSwatch;
  final MaterialColor textColorPrimary;
  final MaterialColor whiteColorPrimary;
  final Color transparentColor;
  final Color blacktextColor;
  final Color hinttextColor;
  final Color roundCircleColor;
  final Color indicatorColor;

  const AppColorPalette(
      {required this.primarySwatch,
        required this.darkSwatch,
        required this.secondarySwatch,
        required this.additionalSwatch1,
        required this.additionalSwatch2,
        required this.yellowSwatch3,
        required this.purpleSwatch,
        required this.redSwatch,
        required this.greenSwatch,
        required this.textColorPrimary,
        required this.whiteColorPrimary,
        required this.transparentColor,
        required this.blacktextColor,
        required this.hinttextColor,
        required this.indicatorColor,
        required this.roundCircleColor});
}

const AppColorPalette lightColorPalette = AppColorPalette(
  primarySwatch: MaterialColor(800, {
    900: Color(0xFF2F3462),
    800: Color(0xFF3D447B),
    700: Color(0xFF282C48),
    600: Color(0xFF282C55),
    400: Color(0x992F3462),
    300: Color(0x802F3462),
    200: Color(0x662F3462),
    100: Color(0x1A2F3462),
  }),
  darkSwatch: MaterialColor(800, {
    900: Color(0xFF283036),
    700: Color(0xFF1E1F20),
    600: Color(0x661E1F20),
  }),
  secondarySwatch: MaterialColor(600, {
    900: Color(0xFF009FD4),
    800: Color(0xE6009FD4),
    600: Color(0xB3009FD4),
    400: Color(0x80009FD4),
    200: Color(0x66009FD4),
    100: Color(0x33009FD4),
    50: Color(0x1A009FD4),
  }),
  additionalSwatch1: MaterialColor(800, {
    800: Color(0xFFFF5A75),
    600: Color(0xCCFF5A75),
    400: Color(0x99FF5A75),
    200: Color(0x66FF5A75),
    100: Color(0x33FF5A75),
  }),
  additionalSwatch2: MaterialColor(800, {
    100: Color(0xFF9DF4F4),
  }),
  yellowSwatch3: MaterialColor(800, {
    100: Color(0xFFF7931A),
  }),
  purpleSwatch:
  MaterialColor(900, {900: Color(0xFF8146EB), 800: Color(0xFF627EEA)}),
  greenSwatch: MaterialColor(900, {
    900: Color(0xFF3CB054),
  }),
  redSwatch: MaterialColor(900, {
    900: Color(0xFFB30D23),
    100: Color(0xFFFF5A75),
  }),
  whiteColorPrimary: MaterialColor(900, {
    900: Color(0xFFFFFFFF),
    800: Color(0xffFEFEFE),
    700: Color(0xffF7F7F7),
    600: Color(0xffFEFEFE),
    400: Color(0x66fefefe),
    200: Color(0x33fefefe),
    100: Color(0xFF757575),
  }),
  textColorPrimary: MaterialColor(900, {
    100: Color(0xFF00A7FF),
    200: Color(0xFF009FD4),
    300: Color(0xFF009DF4),
  }),
  blacktextColor: Color(0xFF2D2F35),
  transparentColor: Colors.transparent,
  hinttextColor: Color(0xff757575),
  indicatorColor: Color(0xff8F92A1),
  roundCircleColor: Color(0xff8F92A1),
);
 TextTheme lightTextTheme = TextTheme(
  ///Mobile/Header1
  displayLarge: TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Color(0xFF2F3462),
  ),

  ///Mobile/Header2
  displayMedium: TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Color(0xFF2F3462),
  ),

  ///Mobile/Header3
  displaySmall: TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Color(0xFF2F3462),
  ),

  ///Mobile/Header4
  headlineMedium: TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: Color(0xFF2F3462),
  ),
  headlineSmall: TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: Color(0xFF2F3462),
  ),

  ///Mobile/Text Body
  bodyLarge: TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0xFF2F3462),
  ),

  ///Mobile/Additional
  bodyMedium: TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: Color(0xFF2F3462),
  ),

  ///Mobile/Additional2
  titleMedium: TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: Color(0xFF2F3462),
  ),

  ///Desktop/Additional
  titleSmall: TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: Color(0xFF2F3462),
  ),
  labelMedium: TextStyle(
    color: Color(0xffA5ADC0),
    fontWeight: FontWeight.w400,
    fontSize: 12.sp,
    height: 1.2,
  ),
);
