// Guards the GetX -> flutter_localizations migration.
//
// The French copy used to live in a GetX `Translations` map looked up with
// `.tr`; it now comes from lib/l10n/app_fr.arb through the generated
// AppLocalizations.

import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _localizationsFor(
  WidgetTester tester,
  Locale locale,
) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (BuildContext context) {
          l10n = AppLocalizations.of(context)!;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  testWidgets('English strings resolve', (WidgetTester tester) async {
    final AppLocalizations l10n = await _localizationsFor(
      tester,
      const Locale('en'),
    );

    expect(l10n.signIn, 'Sign in');
    expect(l10n.resetMyPassword, 'Reset my password');
    expect(l10n.businessEmail, 'Business email');
  });

  testWidgets('French strings resolve', (WidgetTester tester) async {
    final AppLocalizations l10n = await _localizationsFor(
      tester,
      const Locale('fr'),
    );

    expect(l10n.signIn, "S'identifier");
    expect(l10n.resetMyPassword, 'Réinitialiser mon mot de passe');
    expect(l10n.businessEmail, 'E-mail professionnel');
  });

  test('both locales are advertised as supported', () {
    expect(
      AppLocalizations.supportedLocales.map((Locale l) => l.languageCode),
      containsAll(<String>['en', 'fr']),
    );
  });
}
