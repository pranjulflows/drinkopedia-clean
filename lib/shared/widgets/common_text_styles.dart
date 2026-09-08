import 'package:drinkopedia/core/constant_strings/app_constants.dart';
import 'package:drinkopedia/core/theme/color_style/app_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


/*
  This file contains all the text styles used in the app. We write it in single file, so that in future,
  if we want to change , it will be very easy to change text style in the entire app.
 */


TextStyle? profileName(BuildContext context) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: lightColorPalette.whiteColorPrimary.shade800,
      fontWeight: FontWeight.w600,
      height: 1.24,
      fontSize: 14.sp,
      fontFamily: AppConstants.rota);
}

TextStyle? headingAndlargebuttonlabel(
    {required BuildContext context, Color? color}) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
    color: color ?? lightColorPalette.whiteColorPrimary.shade800,
    fontWeight: FontWeight.w700,
    fontSize: 16.sp,
    fontFamily: AppConstants.rota,
    letterSpacing: 0.6,
    height: 1.24,
  );
}

TextStyle? textFieldsStyle(
    {required BuildContext context, Color? color}) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: color ?? lightColorPalette.whiteColorPrimary.shade700,
      fontWeight: FontWeight.w400,
      fontSize: 16.sp,
      fontFamily: AppConstants.rota,
      letterSpacing: 0.41,
      height: 1.24);
}

TextStyle? SmallButtonLabel({required BuildContext context, Color? color}) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
    color: color ?? lightColorPalette.whiteColorPrimary.shade800,
    fontWeight: FontWeight.w700,
    fontSize: 14.sp,
    fontFamily: AppConstants.rota,
    letterSpacing: 0.6,
    height: 1.24,
  );
}

TextStyle? actionSheet(
    {required BuildContext context, Color? color}) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
    color: color ?? lightColorPalette.whiteColorPrimary.shade800,
    fontWeight: FontWeight.w400,
    fontSize: 14.sp,
    fontFamily: AppConstants.rota,
    letterSpacing: 0.6,
    height: 1.57,
  );
}











