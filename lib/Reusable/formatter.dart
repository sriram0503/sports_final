import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A custom [TextInputFormatter] for NRIC (National Registration Identity Card) numbers.
///
/// This formatter inserts a separator at specific intervals based on the length of the input.
/// It handles both adding and deleting characters while maintaining the format.
class NricFormatter extends TextInputFormatter {
  final String separator;

  /// Creates an [NricFormatter] with the given [separator].
  NricFormatter({required this.separator});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final String oldS = oldValue.text;
    final String newS = newValue.text;
    bool endsWithSeparator = false;

    // Check if the previous text ended with a separator before modification
    for (final char in separator.characters) {
      if (oldS.isNotEmpty && oldS.substring(0, oldS.length).endsWith(char)) {
        endsWithSeparator = true;
        break; // Found separator, no need to check further
      }
    }

    // Logic for adding text
    if (newS.length > oldS.length) {
      final String cleanNewS = newS.replaceAll(separator, '');
      // print('CLEAN add: $cleanNewS'); // For debugging

      // Insert separator if length matches specific patterns (e.g., for NRIC-like formats)
      // This logic assumes a specific NRIC format like XXXXXX-X or XXXXXXX-X
      // Adjust the modulo values (6 and 8) if your NRIC format rules are different.
      if (!endsWithSeparator && cleanNewS.length > 1) {
        if (cleanNewS.length == 7 || cleanNewS.length == 9) { // Assuming a 7-digit part and an 8-digit part or similar
          return newValue.copyWith(
            text: newS.substring(0, newS.length - 1) +
                separator +
                newS.characters.last,
            selection: TextSelection.collapsed(
              offset: newValue.selection.end + separator.length,
            ),
          );
        }
      }
    }
    // Logic for deleting text
    else if (newS.length < oldS.length) {
      // If a separator was just deleted, remove it fully
      if (endsWithSeparator && newS.isNotEmpty && oldS.length - newS.length == separator.length) {
        final String cleanOldS = oldS.substring(0, oldS.length - 1).replaceAll(separator, '');
        // print('CLEAN remove: $cleanOldS'); // For debugging

        if (cleanOldS.isNotEmpty && (cleanOldS.length == 6 || cleanOldS.length == 8)) {
          return newValue.copyWith(
            text: newS.substring(0, newS.length - (separator.length - 1)), // Adjusting to remove the separator
            selection: TextSelection.collapsed(
              offset: newValue.selection.end,
            ),
          );
        }
      }
    }

    // Default return if no formatting is applied
    return newValue;
  }
}