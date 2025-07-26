import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sports_c/Reusable/color.dart';
import 'package:sports_c/Reusable/text_styles.dart';

class AlternativePhoneField extends StatefulWidget {
  final Function(String completePhoneNumber) onPhoneChanged;
  final TextEditingController? controller;

  const AlternativePhoneField({
    super.key,
    required this.onPhoneChanged,
    this.controller,
  });

  @override
  State<AlternativePhoneField> createState() => _AlternativePhoneFieldState();
}

class _AlternativePhoneFieldState extends State<AlternativePhoneField> {
  List<TextInputFormatter> formatters = [LengthLimitingTextInputFormatter(10)];
  final FocusNode _focusNode = FocusNode();
  Color borderColor = Colors.grey.withOpacity(0.5);

  final Map<String, int> countryMaxLengths = {
    'IN': 10,
    'US': 10,
    'AE': 9,
    'GB': 10,
    'AU': 9,
  };

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        borderColor = _focusNode.hasFocus
            ? appPrimaryColor
            : Colors.grey.withOpacity(0.5);
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: 70,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent), // Removed outer border
          borderRadius: BorderRadius.circular(15),
        ),
        child: IntlPhoneField(
          focusNode: _focusNode,
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Alternative Number',
            labelStyle: MyTextStyle.f14(greyColor),
            floatingLabelStyle: TextStyle(color: appPrimaryColor),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: appPrimaryColor),
            ),
          ),
          initialCountryCode: 'IN',
          showCountryFlag: false,
          showDropdownIcon: false,
          flagsButtonMargin: const EdgeInsets.only(right: 0),
          flagsButtonPadding: const EdgeInsets.all(0),
          dropdownIconPosition: IconPosition.trailing,
          inputFormatters: formatters,
          keyboardType: TextInputType.number,
          style: MyTextStyle.f15(greyColor, weight: FontWeight.w400),
          cursorColor: appPrimaryColor,
          onChanged: (phone) {
            widget.onPhoneChanged(phone.completeNumber);
          },
          onCountryChanged: (country) {
            final maxLen = countryMaxLengths[country.code] ?? 10;
            setState(() {
              formatters = [LengthLimitingTextInputFormatter(maxLen)];
            });
          },
        ),
      ),
    );
  }
}
