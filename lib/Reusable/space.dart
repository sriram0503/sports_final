import 'package:flutter/material.dart';
import 'package:sports_c/Reusable/color.dart';
import 'package:sports_c/Reusable/text_styles.dart';

Widget verticalSpace({double height = 8.0}) {
  return SizedBox(
    height: height,
  );
}

Widget horizontalSpace({double width = 8.0}) {
  return SizedBox(
    width: width,
  );
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.height,
    this.width,
    this.fontSize,
    required this.buttonText,
    this.color,
    this.onTap,
  });

  final double? height;
  final double? width;
  final double? fontSize;
  final String buttonText;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: color ?? appPrimaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              buttonText,
              style: MyTextStyle.f16(
                whiteColor,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
