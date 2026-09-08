import 'package:get/get.dart';

extension StringExtensions on String? {
  String? toStringConversion() {
    if (this == "null" || this == null) return null;
    return this;
  }

  int toIntConversion() {
    var string = this ?? "";
    if (string != "" && string != "null" && string.isNumericOnly) {
      return int.parse(string);
    }
    return 0;
  }

  int toIntConversionDefaultOne() {
    var string = this ?? "";
    if (string != "" && string != "null" && string.isNumericOnly) {
      return int.parse(string);
    }
    return 1;
  }

  double toDoubleConversionWithRoundOff() {
    var string = this ?? "";
    if (string != "" &&
        string != "null" &&
        RegExp(r'\d+([\.]\d+)?$').hasMatch(string)) {
      var stringWithRound = double.parse(string).toStringAsFixed(2);
      return double.parse(stringWithRound);
    }
    return 0.0;
  }

  double toDoubleConversionWithoutRoundOff() {
    var string = this ?? "";
    if (string != "" &&
        string != "null" &&
        RegExp(r'\d+([\.]\d+)?$').hasMatch(string)) {
      return double.parse(string);
    }
    return 0.0;
  }
}
