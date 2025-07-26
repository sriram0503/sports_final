import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sports_c/Reusable/color.dart';
import 'package:sports_c/Reusable/formatter.dart';
import 'package:sports_c/Reusable/text_styles.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField
      ({
    super.key,
    required this.hint,
    this.readOnly = false,
    required this.controller,
    this.baseColor = appPrimaryColor,
    this.borderColor = appGreyColor,
    this.errorColor = redColor,
    this.inputType = TextInputType.text,
    this.obscureText = false,
    this.maxLength = TextField.noMaxLength,
    this.maxLine,
    this.onChanged,
    this.onTap,
    this.validator,
    this.showSuffixIcon = false,
    this.suffixIcon,
    this.countryCodePicker,
    this.prefixText,
    this.textInputFormatter,
    this.isUpperCase = false,
    this.enableNricFormatter = false,
    this.height,
    this.prefixIcon,
    this.keyboardType,
  });

  final String hint;
  final bool readOnly;
  final TextEditingController controller;
  final Color baseColor;
  final Color borderColor;
  final Color errorColor;
  final TextInputType inputType;
  final bool obscureText;
  final int maxLength;
  final int? maxLine;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final bool showSuffixIcon;
  final Widget? suffixIcon;
  final Widget? countryCodePicker;
  final String? prefixText;
  final FilteringTextInputFormatter? textInputFormatter;
  final bool isUpperCase;
  final bool enableNricFormatter;
  final double? height;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;



  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (countryCodePicker != null) countryCodePicker!,
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: TextSelectionTheme(
              data: const TextSelectionThemeData(
                cursorColor: appPrimaryColor,
                selectionColor: appPrimaryColor,
                selectionHandleColor: appPrimaryColor,
              ),
              child: TextFormField(
                style: MediaQuery.of(context).size.width < 650
                    ? MyTextStyle.f16(blackColor, weight: FontWeight.w400)
                    : MyTextStyle.f20(blackColor, weight: FontWeight.w400),
                controller: controller,
                readOnly: readOnly,
                obscureText: obscureText,
                keyboardType: inputType,
                onTap: onTap,
                expands: false,
                textCapitalization: isUpperCase
                    ? TextCapitalization.characters
                    : TextCapitalization.none,
                inputFormatters: [
                  if (textInputFormatter != null)
                    textInputFormatter!, // Using renamed property
                  if (isUpperCase)
                    FilteringTextInputFormatter.allow(RegExp("[A-Z0-9 ]")),
                  if (enableNricFormatter) NricFormatter(separator: '-'),
                  LengthLimitingTextInputFormatter(maxLength),
                ],
                maxLength: maxLength,
                maxLines: maxLine ?? 1,
                onChanged: onChanged,
                validator: validator,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: height ?? 12.0,
                    horizontal: 12.0,
                  ),
                  counterText: "",
                  hintText: hint,
                  hintStyle: MediaQuery.of(context).size.width < 650
                      ? MyTextStyle.f14(greyColor, weight: FontWeight.w500)
                      : MyTextStyle.f18(greyColor, weight: FontWeight.w300),
                  prefixText: prefixText,
                  prefixStyle: MediaQuery.of(context).size.width < 650
                      ? MyTextStyle.f14(blackColor, weight: FontWeight.w300)
                      : MyTextStyle.f18(blackColor, weight: FontWeight.w300),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: baseColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: errorColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: errorColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: showSuffixIcon ? suffixIcon : null,
                ),

              ),
            ),
          ),
        ),
      ],
    );
  }
}
