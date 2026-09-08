import 'package:drinkopedia/core/common_ui/button/custom_icon_button.dart';
import 'package:drinkopedia/core/common_ui/decoration/common_text_styles.dart';
import 'package:drinkopedia/core/common_ui/image_assets/asset.dart';
import 'package:drinkopedia/core/common_ui/image_assets/asset_widget.dart';
import 'package:drinkopedia/core/theme/color_style/app_color_palette.dart';
import 'package:drinkopedia/core/utills/image_resources.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';



// This function returns the widget, which is used for common app bar.
PreferredSizeWidget commonAppBar({String? title, Function()? onTapLeadingIcon}){
  return AppBar(
    backgroundColor: lightColorPalette.primarySwatch.shade900,
    leading: Padding(
      padding: EdgeInsets.only(left: 22.w),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomIconButton(
          padding:
          EdgeInsets.only(bottom: 6.h, right: 8.w, top: 6.h, left: 8.w),
          onPressed: () {
            onTapLeadingIcon != null ? onTapLeadingIcon() : Get.back();
          },
          child: AssetWidget(
            asset: Asset(type: AssetType.svg, path: ImageResource.back_button),
            height: 16.h,
            width: 16.w,
          ),
        ),
      ),
    ) ,
    title: Text(
      title ?? "",
      style: headingAndlargebuttonlabel(
          context: Get.context!,
          color: lightColorPalette.whiteColorPrimary.shade900),
    ),
  );
}