/// Values that arrive verbatim in API payloads.
///
/// These are wire-protocol constants, **not** user-facing copy, so they are
/// never translated. Localised UI strings live in `lib/l10n/*.arb` and are
/// read through `AppLocalizations.of(context)`.
class StringsResources {
  StringsResources._();

  static const String success = "SUCCESS";
  static const String fail = "FAIL";
}
