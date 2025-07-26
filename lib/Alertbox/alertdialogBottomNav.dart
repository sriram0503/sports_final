import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sports_c/Reusable/color.dart';
import 'package:sports_c/Reusable/text_styles.dart';

Future<bool> showExitConfirmationDialog(BuildContext context, Size size) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        "Please confirm",
        style: MyTextStyle.f16(appPrimaryColor, weight: FontWeight.bold),
      ),
      content: Text(
        "Are you sure you want to exit?",
        style: MyTextStyle.f13(appSecondaryColor, weight: FontWeight.w400),
      ),
      actions: [
        Container(
          width: size.width * 0.3,
          decoration: BoxDecoration(
            color: whiteColor,
            border: Border.all(color: appPrimaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "No",
              style:
                  MyTextStyle.f13(appSecondaryColor, weight: FontWeight.w400),
            ),
          ),
        ),
        Container(
          width: size.width * 0.3,
          decoration: BoxDecoration(
            color: appPrimaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              SystemNavigator.pop(); // Closes the app
            },
            child: Text(
              "Yes",
              style: MyTextStyle.f13(whiteColor, weight: FontWeight.w400),
            ),
          ),
        ),
      ],
    ),
  );

  return result ?? false;
}
