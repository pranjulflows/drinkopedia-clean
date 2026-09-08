import 'package:drinkopedia/core/common_ui/decoration/common_text_styles.dart';
import 'package:drinkopedia/core/common_ui/decoration/text_filed_decorations.dart';
import 'package:drinkopedia/core/theme/color_style/app_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonPasswordTextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode node;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String hint;
  final Function(String)? onChange;
  final VoidCallback? onTab;
  final String? Function(String?)? validator;
  final bool? showColorBorder;
  final bool? onContinueBool;
  final Color? fillColor;
  final bool? enabled;
  final bool? readOnly;
  final String email;
  final bool? obscureText;
  final Widget suffixIcon;
  final bool showPasswordError;
  final TextAlign textAlign;
  final InputDecoration? decoration;
  final EdgeInsetsGeometry? contentPadding;

  final Function()? onEditingComplete;

  const CommonPasswordTextFieldWidget(
      {Key? key,
        required this.controller,
        required this.node,
        required this.hint,
        required this.keyboardType,
        this.textInputAction = TextInputAction.done,
        required this.email,
        required this.suffixIcon,
        this.showColorBorder,
        this.enabled,
        this.validator,
        this.onContinueBool,
        this.onChange,
        this.onTab,
        this.obscureText,
        required this.showPasswordError,
        this.readOnly = false,
        this.textAlign = TextAlign.center,
        this.decoration,
        this.fillColor,
        this.onEditingComplete,
        this.contentPadding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextFormField(
        onEditingComplete: onEditingComplete,

        obscuringCharacter: '*',
        // defaults to *
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(
              r'(?:[\u2700-\u27bf]|(?:\ud83c[\udde6-\uddff]){2}|[\ud800-\udbff][\udc00-\udfff]|[\u0023-\u0039]\ufe0f?\u20e3|\u3299|\u3297|\u303d|\u3030|\u24c2|\ud83c[\udd70-\udd71]|\ud83c[\udd7e-\udd7f]|\ud83c\udd8e|\ud83c[\udd91-\udd9a]|\ud83c[\udde6-\uddff]|\ud83c[\ude01-\ude02]|\ud83c\ude1a|\ud83c\ude2f|\ud83c[\ude32-\ude3a]|\ud83c[\ude50-\ude51]|\u203c|\u2049|[\u25aa-\u25ab]|\u25b6|\u25c0|[\u25fb-\u25fe]|\u00a9|\u00ae|\u2122|\u2139|\ud83c\udc04|[\u2600-\u26FF]|\u2b05|\u2b06|\u2b07|\u2b1b|\u2b1c|\u2b50|\u2b55|\u231a|\u231b|\u2328|\u23cf|[\u23e9-\u23f3]|[\u23f8-\u23fa]|\ud83c\udccf|\u2934|\u2935|[\u2190-\u21ff])'))
        ],
        maxLines: 1,
        onTap: () {
          // isPasswordHintPopUpVisible
        },
        onChanged: onChange,
        enabled: enabled,
        textAlign: textAlign,
        controller: controller,
        focusNode: node,
        autocorrect: false,
        enableSuggestions: false,
        style: textFieldsStyle(context: context),
        keyboardType: TextInputType.visiblePassword,
        obscureText: obscureText!,
        textInputAction: textInputAction,
        decoration: decoration ??
            InputDecoration(
                border: showPasswordError
                    ? formFieldErrorDecoration()
                    : formFieldDecoration(),
                enabledBorder: showPasswordError
                    ? formFieldErrorDecoration()
                    : formFieldDecoration(),
                disabledBorder: showPasswordError
                    ? formFieldErrorDecoration()
                    : formFieldDecoration(),
                contentPadding: contentPadding ??
                    EdgeInsets.only(left: 24.w, top: 14.h, bottom: 14.h),
                suffixIcon: suffixIcon,
                fillColor:
                fillColor ?? lightColorPalette.primarySwatch.shade800,
                filled: true,
                hintText: hint,
                hintStyle: textFieldsStyle(
                    context: context, color: lightColorPalette.hinttextColor),
                focusedBorder: showPasswordError
                    ? formFieldErrorDecoration()
                    : formFieldDecoration(),
                errorBorder: showPasswordError
                    ? formFieldErrorDecoration()
                    : formFieldErrorDecoration()),
      ),
    );
  }
}