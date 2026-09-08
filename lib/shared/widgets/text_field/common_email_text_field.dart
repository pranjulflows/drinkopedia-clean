import 'package:drinkopedia/core/constant_strings/app_constants.dart';
import 'package:drinkopedia/core/theme/color_style/app_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonEmailTextFieldWidget extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? node;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String hint;
  final Function(String)? onChange;
  final InputDecoration decoration;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final bool? showColorBorder;
  final bool? enabled;
  final bool? readOnly;
  final bool? isCenter;
  final void Function(String)? onFieldSubmitted;

  const CommonEmailTextFieldWidget(
      {Key? key,
        this.controller,
        this.node,
        required this.hint,
        required this.keyboardType,
        this.textInputAction,
        required this.decoration,
        this.showColorBorder,
        this.validator,
        this.onChange,
        this.enabled,
        this.readOnly,
        this.onTap,
        this.isCenter = false,
        this.onFieldSubmitted})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: readOnly ?? false,
      onFieldSubmitted: onFieldSubmitted,
      maxLines: 1,
      autocorrect: false,
      enableSuggestions: false,
      onTap: () {},
      textAlign: TextAlign.center,
      controller: controller,
      focusNode: node,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp('[a-zA-Z0-9@._]'),
        ),
      ],
      onChanged: onChange,
      enabled: true,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color:  lightColorPalette.whiteColorPrimary.shade800,
          fontWeight: FontWeight.w400,
          fontSize: 16.sp,
          fontFamily: AppConstants.rota,
          letterSpacing: 0.41,
          height: 1.24),
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction ?? TextInputAction.next,
      decoration: decoration,
    );
  }
}
