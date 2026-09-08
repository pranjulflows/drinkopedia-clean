import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomIconButton extends StatelessWidget {
  final Widget child;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final void Function()? onPressed;

  const CustomIconButton({
    super.key,
    required this.child,
    this.iconSize,
    this.color,
    required this.onPressed,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: CupertinoThemeData(primaryColor: color ?? Colors.transparent),
      child: CupertinoButton.filled(
        borderRadius: BorderRadius.zero,
        minimumSize: iconSize == null ? null : Size.square(iconSize!),
        padding: padding ?? EdgeInsets.all(12.r),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
