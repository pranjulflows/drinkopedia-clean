import 'package:drinkopedia/core/common_ui/decoration/common_text_styles.dart';
import 'package:drinkopedia/core/common_ui/dimensions/common_dimensions.dart';
import 'package:drinkopedia/core/constant_strings/app_constants.dart';
import 'package:drinkopedia/core/theme/color_style/app_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/*
This class defines the decorations used in the app.
 */


showInputDecoration(
    String hintTxt, OutlineInputBorder border, BuildContext context,
    {bool? showBorder}) {
  return InputDecoration(
    contentPadding: EdgeInsets.symmetric(
        vertical: showBorder != null && showBorder ? 13.h : 14.h,
        horizontal: 12.w),
    focusedBorder: border,
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedErrorBorder: border,
    fillColor: lightColorPalette.primarySwatch.shade800,
    hintText: hintTxt,
    hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: lightColorPalette.hinttextColor,
        fontWeight: FontWeight.w400,
        fontFamily: AppConstants.rota),
    errorBorder: formFieldErrorDecoration(),
    filled: true,
  );
}

showInputProfileDecoration(
    String hintTxt,
    bool showPasswordError,
    BuildContext context,
    Widget suffixIcon,
    Color fillColor,
    ) {
  return InputDecoration(
    contentPadding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 14.h),
    border:
    showPasswordError ? formFieldErrorDecoration() : formFieldDecoration(),
    enabledBorder:
    showPasswordError ? formFieldErrorDecoration() : formFieldDecoration(),
    disabledBorder:
    showPasswordError ? formFieldErrorDecoration() : formFieldDecoration(),
    focusedBorder:
    showPasswordError ? formFieldErrorDecoration() : formFieldDecoration(),
    errorBorder: showPasswordError
        ? formFieldErrorDecoration()
        : formFieldErrorDecoration(),
    suffixIcon: suffixIcon,
    fillColor: fillColor,
    hintText: hintTxt,
    hintStyle: actionSheet(context: context),
    filled: true,
  );
}

formFieldDecoration({Color? color}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(CommonDimensions.commonTextFieldRadius),
    borderSide: BorderSide(
        width: 1,
        style: BorderStyle.solid,
        color: color ?? lightColorPalette.transparentColor),
  );
}

formFieldAcceptDecoration(bool isLogin) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(CommonDimensions.commonTextFieldRadius),
    borderSide: BorderSide(
        width: 1,
        style: BorderStyle.solid,
        color: isLogin
            ? lightColorPalette.additionalSwatch2.shade100
            : lightColorPalette.secondarySwatch.shade900),
  );
}

formFieldErrorDecoration() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(CommonDimensions.commonTextFieldRadius),
    borderSide: BorderSide(
      width: 1,
      color: lightColorPalette.additionalSwatch1.shade800,
      style: BorderStyle.solid,
    ),
  );
}
