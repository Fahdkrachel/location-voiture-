import 'package:flutter/material.dart';

const String _leftToRightOverride = '\u202D';
const String _popDirectionalFormatting = '\u202C';

/// Returns a display-only string that forces the Bidirectional layout engine
/// to display all characters (including Arabic characters) strictly from
/// left to right in their logical sequence.
String preserveBidiOrder(String value) {
  if (value.isEmpty) return value;
  final clean = value.replaceAll('\u202D', '').replaceAll('\u202C', '');
  return '$_leftToRightOverride$clean$_popDirectionalFormatting';
}

String formatMatriculeLabel(String brand, String matricule) {
  return '$brand (${preserveBidiOrder(matricule)})';
}

class MatriculeText extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const MatriculeText(
    this.value, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      preserveBidiOrder(value),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: TextDirection.ltr,
    );
  }
}

/// Custom TextEditingController that ensures matricule input containing Arabic characters
/// is always rendered in the typed LTR order without scrambling, while providing
/// cleanText getter to fetch clean data for the API.
class BidiMatriculeEditingController extends TextEditingController {
  BidiMatriculeEditingController({String? text}) {
    if (text != null && text.isNotEmpty) {
      this.text = _wrap(text);
    }
  }

  static String _wrap(String t) {
    final clean = t.replaceAll('\u202D', '').replaceAll('\u202C', '');
    if (clean.isEmpty) return '';
    return '$_leftToRightOverride$clean$_popDirectionalFormatting';
  }

  String get cleanText => text.replaceAll('\u202D', '').replaceAll('\u202C', '');

  set cleanText(String val) {
    text = _wrap(val);
  }

  @override
  set value(TextEditingValue newValue) {
    final clean = newValue.text.replaceAll('\u202D', '').replaceAll('\u202C', '');
    if (clean.isEmpty) {
      super.value = newValue.copyWith(text: '');
      return;
    }

    final newWrappedText = '$_leftToRightOverride$clean$_popDirectionalFormatting';
    
    int baseOffset = newValue.selection.baseOffset;
    int extentOffset = newValue.selection.extentOffset;

    if (!newValue.text.startsWith(_leftToRightOverride)) {
      baseOffset += 1;
      extentOffset += 1;
    }
    
    baseOffset = baseOffset.clamp(0, newWrappedText.length);
    extentOffset = extentOffset.clamp(0, newWrappedText.length);

    super.value = newValue.copyWith(
      text: newWrappedText,
      selection: TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
      ),
    );
  }
}
