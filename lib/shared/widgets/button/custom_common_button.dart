import 'package:drinkopedia/core/common_ui/decoration/common_text_styles.dart';
import 'package:drinkopedia/core/common_ui/image_assets/asset.dart';
import 'package:drinkopedia/core/common_ui/image_assets/asset_widget.dart';
import 'package:drinkopedia/core/theme/color_style/app_color_palette.dart';
import 'package:drinkopedia/core/utills/enum.dart';
import 'package:drinkopedia/core/utills/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonButton extends StatelessWidget {
  final Color? bgColor, iconColor;
  final String commonButtonBottonText;
  final bool? isEnable;
  final bool? isIconEnable;
  final double? radius;
  final double? elevation;
  final double vertical;
  final double horizontal;
  final double? minWidth;
  final double? minHeight;
  final VoidCallback? onPress;
  final TextStyle? style;
  final ShowImagePositionAt? type;
  final MainAxisAlignment? mainAxisAlignment;
  final double? spaceBetween;
  final String? image;
  final bool? needStyle;

  final Widget? isShowOnlyImage;

  CommonButton(
      {Key? key,
        this.bgColor = const Color(0xff009FD4),
        required this.commonButtonBottonText,
        this.radius = 16.0,
        this.elevation = 0.0,
        this.vertical = 18.0,
        this.horizontal = 0.0,
        this.minWidth = 200,
        this.isEnable = true,
        this.isIconEnable = true,
        this.style,
        this.needStyle,
        this.mainAxisAlignment,
        this.spaceBetween,
        this.minHeight,
        this.image,
        required this.onPress,
        this.iconColor,
        this.type = ShowImagePositionAt.none,
        this.isShowOnlyImage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          if (isRedundentClick(DateTime.now())) {
            // print('hold on, processing');
            return;
          }
          onPress!();
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius!)),
          backgroundColor: bgColor,
          disabledBackgroundColor: bgColor?.withOpacity(0.5),
          textStyle: style ?? headingAndlargebuttonlabel(context: context),

          splashFactory: isEnable == true ? null : NoSplash.splashFactory,
          elevation: elevation,
          maximumSize: Size(minWidth!, minHeight ?? 56.h),
          minimumSize: Size(minWidth!, minHeight ?? 56.h),
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: horizontal),

          // padding: EdgeInsets.zero,
          // // minimumSize: Size(50, 30),
          // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: isShowOnlyImage ??
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: mainAxisAlignment == null
                  ? MainAxisAlignment.center
                  : mainAxisAlignment!,
              children: [
                type == ShowImagePositionAt.left
                    ? AssetWidget(
                  color: needStyle != null && needStyle! && !isIconEnable!
                      ? lightColorPalette.whiteColorPrimary.shade800
                      .withAlpha(90)
                      : lightColorPalette.whiteColorPrimary.shade800,
                  height: 12.h,
                  width: 12.w,
                  asset: Asset(type: AssetType.svg, path: image!),
                )
                    : Container(),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: spaceBetween == null ? 5.w : spaceBetween!),
                    child: Text(
                      textAlign: TextAlign.center,
                      commonButtonBottonText,
                      style: needStyle != null && needStyle!
                          ? style
                          : headingAndlargebuttonlabel(context: context),
                    ),
                  ),
                ),
                type == ShowImagePositionAt.right
                    ? AssetWidget(
                  color: iconColor ?? Colors.transparent,
                  boxFit: BoxFit.fill,
                  asset: Asset(type: AssetType.svg, path: image!),
                )
                    : Container(),
              ],
            ));
  }
}

class SmallCommonButton extends StatelessWidget {
  final Color? bgColor, disabledBackgroundColor;
  final String commonButtonBottonText;
  final double? radius;
  final double elevation;
  final bool? isDashBoard;

  final TextStyle? style;
  final Function()? onPress;
  final TextAlign? textAlign;

  final double minWidth;

  final double minHeight;
  final double? horizontal;
  final double? vertical;

  const SmallCommonButton(
      {Key? key,
        this.bgColor = const Color(0xff009FD4),
        required this.commonButtonBottonText,
        this.radius,
        this.elevation = 0.0,
        this.isDashBoard,
        this.style,
        this.onPress,
        this.textAlign,
        this.disabledBackgroundColor,
        required this.minWidth,
        required this.minHeight,
        this.horizontal,
        this.vertical})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius ?? 8.r)),
          backgroundColor: bgColor,
          disabledBackgroundColor: disabledBackgroundColor,
          elevation: elevation,
          padding: EdgeInsets.symmetric(
              horizontal: horizontal ?? 0, vertical: vertical ?? 0),
          minimumSize: Size(minWidth, minHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          commonButtonBottonText,
          style: SmallButtonLabel(context: context),
          textAlign: textAlign,
        ));
  }
}
