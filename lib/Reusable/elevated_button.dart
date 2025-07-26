import 'package:flutter/material.dart';
import 'package:sports_c/Reusable/color.dart';
import 'package:sports_c/Reusable/text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: appPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: MyTextStyle.f18(whiteColor),
        ),
      ),
    );
  }
}
