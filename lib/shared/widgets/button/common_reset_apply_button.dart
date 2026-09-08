import 'package:drinkopedia/core/common_ui/button/custom_common_button.dart';
import 'package:drinkopedia/core/common_ui/dimensions/common_dimensions.dart';
import 'package:drinkopedia/core/common_ui/image_assets/asset_widget.dart';
import 'package:drinkopedia/core/theme/color_style/app_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../image_assets/asset.dart';

/*
This class defines the decorations used in the app.
 */

class CommonResetAndApplyButton extends StatelessWidget {
  final void Function()? resetOnTap, applyButtonOnTap;
  final String btnText;
  final String? icon;
  final double? bottomPadding, topPadding;

  final Color? bgColor;

  const CommonResetAndApplyButton(
      {super.key,
        required this.resetOnTap,
        required this.applyButtonOnTap,
        required this.btnText,
        this.bottomPadding,
        this.icon,
        this.bgColor,
        this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: topPadding ?? 24.h,
          left: CommonDimensions.commonButtonLeftRightPadding,
          right: CommonDimensions.commonButtonLeftRightPadding,
          bottom: bottomPadding ?? CommonDimensions.commonButtonBottomHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
              onPressed: resetOnTap,
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                  backgroundColor: lightColorPalette.secondarySwatch.shade900,
                  minimumSize: Size(56.w, 56.h)),
              child: icon != null && icon != ""
                  ? AssetWidget(
                color: Colors.white,
                asset: Asset(path: icon!, type: AssetType.svg),
              )
                  : Icon(
                Icons.replay,
                color: lightColorPalette.whiteColorPrimary.shade900,
              )),

          //Apply button
          Container(
            height: 56.h,
            width: 240.w,
            child: CommonButton(
                radius: 16.r,
                commonButtonBottonText: btnText,
                bgColor: bgColor ?? lightColorPalette.secondarySwatch.shade900,
                onPress: applyButtonOnTap),
          ),
        ],
      ),
    );
  }
}
