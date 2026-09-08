import 'package:drinkopedia/shared/widgets/button/custom_icon_button.dart';
import 'package:drinkopedia/shared/widgets/common_text_styles.dart';
import 'package:drinkopedia/shared/widgets/image/asset.dart';
import 'package:drinkopedia/shared/widgets/image/asset_widget.dart';
import 'package:drinkopedia/app/theme/app_color_palette.dart';
import 'package:drinkopedia/core/constants/image_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// This function returns the widget, which is used for common app bar.
PreferredSizeWidget commonAppBar({
  required BuildContext context,
  String? title,
  Function()? onTapLeadingIcon,
}) {
  return AppBar(
    backgroundColor: lightColorPalette.primarySwatch.shade900,
    leading: Padding(
      padding: EdgeInsets.only(left: 22.w),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomIconButton(
          padding: EdgeInsets.only(
            bottom: 6.h,
            right: 8.w,
            top: 6.h,
            left: 8.w,
          ),
          onPressed: () {
            onTapLeadingIcon != null
                ? onTapLeadingIcon()
                : Navigator.of(context).maybePop();
          },
          child: AssetWidget(
            asset: Asset(type: AssetType.svg, path: ImageResource.backButton),
            height: 16.h,
            width: 16.w,
          ),
        ),
      ),
    ),
    title: Text(
      title ?? "",
      style: headingAndlargebuttonlabel(
        context: context,
        color: lightColorPalette.whiteColorPrimary.shade900,
      ),
    ),
  );
}
