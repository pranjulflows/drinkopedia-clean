# Publishing Drinkopedia on Google Play

Everything Play Console asks for, in the order it asks, with the answer for
each item. The answers are based on what the app actually does as of
September 2026. If the app starts collecting data, showing ads or adding
accounts, the **App content** answers below must change with it.

## 0. Before you open Play Console

These live outside Play Console, but the first upload is blocked until they
are done.

| # | What | Why |
|---|---|---|
| 1 | Release `development` → `main` | PRs #13–#15 are merged into `development`. #15 is what makes the build uploadable: package name `com.macamps.drinkopedia`, the INTERNET permission, and release signing. |
| 2 | **Buy TheCocktailDB's premium key** | The free test key `1` is not licensed for a public store release. Check thecocktaildb.com for current terms. The premium API may live under `/v2/` rather than `/v1/`, and `ApiSources.cocktailDbBaseUrl` hardcodes `/v1/`, so test the key against both before building. |
| 3 | **Credit Wikipedia in the app** | Many stories come from Wikipedia under CC BY-SA, which requires visible attribution where the text is shown, such as a line under "The Story". Crediting it in the store description alone is not enough. |
| 4 | **Create the upload key** (once, and keep it safe) | Play rejects debug-signed bundles. See section 7. |
| 5 | **Host the privacy policy** | Required for every app. See section 5. |
| 6 | Replace the launcher icon | The installed app still shows Flutter's default logo while the store icon is the bottle mark. Play expects the two to match. |
| 7 | *(optional)* Android Studio → SDK Manager → SDK Tools → **Android SDK Command-line Tools** | Silences Flutter's "failed to strip debug symbols" message at the end of `flutter build appbundle`. The bundle is fine either way. |

## 1. Developer account

- Sign up at <https://play.google.com/console>: **US$25 once**, plus identity
  verification.
- **Personal accounts created after 13 November 2023** can't publish straight
  to production. You first need a **closed test with at least 12 testers who
  stay opted in for 14 days in a row**, and then you apply for production
  access. Line up 12 people (friends, family, a Google Group) before you start.
  Organisation accounts skip this step but need a D-U-N-S number.

## 2. Create the app

Play Console → **Create app**

| Field | Answer |
|---|---|
| App name | `Drinkopedia: Spirits Guide` |
| Default language | English (United States) – en-US |
| App or game | App |
| Free or paid | **Free**. A free app can never become paid later. |
| Declarations | Tick Developer Program Policies and US export laws |

## 3. Main store listing

Grow → Store presence → **Main store listing**

| Field | Source | Limit |
|---|---|---|
| App name | `listing/en-US/title.txt` | 30 |
| Short description | `listing/en-US/short_description.txt` | 80 |
| Full description | `listing/en-US/full_description.txt` | 4000 |
| App icon | `icon-512.png` | 512 × 512 PNG |
| Feature graphic | `feature-graphic-1024x500.png` | 1024 × 500 |
| Phone screenshots | `phone-screenshots/01…06.png`, in file order | 2–8 |
| Tablet screenshots | Leave empty. Only needed to be featured on tablets. | — |
| Video | Leave empty | — |

The copy follows Play's metadata policy. It avoids "best" and "#1", doesn't
repeat keywords, has no calls to action and no emoji, and claims nothing the
app doesn't do. Spirit names, including the ones people search for (whiskey,
bourbon, gin, rum, tequila, mezcal and others), appear once each in natural
sentences, which is what Play's search indexes. The listing never states how
many spirits there are, because that number changes with the catalogue.

## 4. Store settings

Grow → Store presence → **Store settings**

| Field | Answer |
|---|---|
| App category | **Food & Drink**. Books & Reference is the alternative, but drink searches browse Food & Drink. |
| Tags | Up to 5 from Play's list; pick the drink and reference ones closest to the app |
| Email | Your support address (required, shown publicly) |
| Website | `https://github.com/pranjulflows/drinkopedia-clean` (optional) |
| Phone | Leave empty |

## 5. App content

Policy → **App content**. Every item has to be completed before release.

| Declaration | Answer | Why |
|---|---|---|
| **Privacy policy** | `https://pranjulflows.github.io/drinkopedia-clean/privacy-policy.html` | Source: `docs/privacy-policy.md`, served by GitHub Pages from `development`, folder `/docs`. Check that the URL loads before pasting it in. |
| **Ads** | No, the app doesn't contain ads | No ad SDK in `pubspec.yaml` |
| **App access** | All functionality is available without special access | No login |
| **Content rating** | Fill in the IARC questionnaire. Category: *Reference, News, or Educational*. Answer **yes** to references to alcohol, and **no** to violence, sexual content, gambling, user interaction, sharing location and purchases. | The rating is calculated from your answers. Alcohol references usually land around teen or 12+/16+ depending on the region. |
| **Target audience** | **18 and over only**. Answer no to "could unintentionally appeal to children". | An alcohol reference app. Keeps it out of the Families programme. |
| **News app** | No | |
| **Data safety** | Does the app collect or share user data? **No.** | Nothing leaves the device except requests to TheCocktailDB that carry no user data. Taste picks are stored on-device only, and Play doesn't count on-device data as "collected". |
| **Advertising ID** | No | No ad or analytics SDK, and the manifest doesn't declare `AD_ID` |
| **Government apps** | No | |
| **Financial features** | None | |
| **Health apps** | None | |

If you ever add Firebase, Crashlytics, analytics, ads or accounts, redo
**Data safety**, **Ads** and **Advertising ID** before that build ships.

## 6. Countries and pricing

Production → **Countries / regions**: add the countries you want. Drinkopedia
doesn't sell alcohol, so Play's alcohol-sales restrictions don't apply, but
you can leave out markets where alcohol content is sensitive. Price: free.

## 7. Build and upload

**The upload key.** Create it once, back up the file and both passwords
somewhere safe, and never commit them. The repo is public.

```bash
keytool -genkey -v -keystore ~/drinkopedia-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` (gitignored):

```
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/Users/<you>/drinkopedia-upload.jks
```

**The bundle**:

```bash
flutter build appbundle --release --dart-define=COCKTAILDB_KEY=<premium key>
```

Upload `build/app/outputs/bundle/release/app-release.aab`. Accept **Play App
Signing** when offered: Google holds the app signing key, and yours is only
the upload key, so a lost upload key can be reset.

Every upload needs a higher version code. Bump `version:` in `pubspec.yaml`
(`1.0.0+1` → `1.0.1+2`; the number after the `+` is the version code).

## 8. Testing → production

1. **Internal testing**: upload the bundle, add yourself, and install it from
   the opt-in link. Check that spirits load, since that's the INTERNET
   permission and the premium key working in a real release build.
2. **Closed testing**: the same bundle, 12+ testers, 14 consecutive days
   (personal accounts only).
3. **Apply for production access** (Dashboard). Play asks how you tested and
   what feedback you got.
4. **Production** → Create release → roll out. Reviews usually take from a few
   hours to a few days, and a first review can take longer.
