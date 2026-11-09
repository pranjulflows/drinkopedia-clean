---
title: Android release pipeline
---

# Android release pipeline

`.github/workflows/release-android.yml` builds a signed Android App Bundle and
uploads it to Play Console's **internal testing** track.

It never publishes to production. Promoting a build to real users stays a
deliberate click in Play Console — and production needs the closed-testing
requirement met first in any case.

iOS is not automated. It needs a macOS runner and signing certificates, and iOS
builds are currently blocked on the project's deployment target (13.0) being
below what the installed Xcode supports.

## What a release run does

1. Refuses to start unless every secret below is set.
2. Works out the version, and refuses anything that is not `major.minor.patch`.
3. Refuses to release a commit that is not on `main`.
4. Runs `flutter analyze` and the full test suite. A tag can point at a commit
   CI never saw green, and a broken build must not reach even internal testers.
5. Builds the bundle, signed with the upload key.
6. Checks the signature is the upload key and not the debug key.
7. Keeps the bundle as a 90-day workflow artifact, so a failed upload does not
   mean rebuilding.
8. Uploads to the internal testing track, then deletes the signing material.

## Version numbers

Tag `v1.0.1` gives version name `1.0.1` and version code `10001`, from
`major × 10000 + minor × 100 + patch`.

Play refuses a version code it has already seen, so deriving the code from the
version means the same release can never be uploaded twice by accident, and
re-running a failed job is safe right up until the upload succeeds. It also
clears the version code `1` already uploaded by hand.

Keep minor and patch below 100. `pubspec.yaml`'s own `version:` is ignored on a
release run — the tag decides.

## One-time setup

### 1. The six secrets

Run these from the repo. They read the values rather than echoing them, so
nothing lands in your shell history. The last three come from
`android/key.properties`, which is gitignored and already on your machine.

```bash
base64 -i ~/Documents/Drinkopedia.jks | gh secret set ANDROID_KEYSTORE_BASE64
grep '^storePassword=' android/key.properties | cut -d= -f2- | tr -d '\n' | gh secret set ANDROID_KEYSTORE_PASSWORD
grep '^keyPassword=' android/key.properties | cut -d= -f2- | tr -d '\n' | gh secret set ANDROID_KEY_PASSWORD
grep '^keyAlias=' android/key.properties | cut -d= -f2- | tr -d '\n' | gh secret set ANDROID_KEY_ALIAS
```

Then the premium TheCocktailDB key, typed rather than stored in a file:

```bash
read -rs k && printf '%s' "$k" | gh secret set COCKTAILDB_KEY && unset k
```

`PLAY_SERVICE_ACCOUNT_JSON` comes from step 2.

### 2. A Play Developer API service account

1. **Play Console → Setup → API access.** Link a Google Cloud project if you
   have not already.
2. In that Google Cloud project: **IAM & Admin → Service Accounts → Create**.
   Name it something like `play-publisher`. No project roles are needed — the
   permissions that matter are granted in Play Console.
3. On the new account: **Keys → Add key → Create new key → JSON**. A file
   downloads. Treat it like a password.
4. Back in **Play Console → Users and permissions → Invite new user**, invite
   the service account's email address. Give it access to Drinkopedia with
   **Release to testing tracks** (and **View app information**). It does not
   need production release permission, and should not have it.
5. Store it, then delete the download:

```bash
gh secret set PLAY_SERVICE_ACCOUNT_JSON < ~/Downloads/play-publisher-*.json
rm ~/Downloads/play-publisher-*.json
```

New Play permissions sometimes take a few hours to take effect. If the first
run fails on permissions, that is usually why.

## Releasing

```bash
git checkout main && git pull
git tag v1.0.1
git push origin v1.0.1
```

Watch it with `gh run watch`, or in the Actions tab. When it finishes, the
build is in Play Console under **Testing → Internal testing**.

To build without tagging — a rebuild, or a push to a different testing track —
use **Actions → Release (Android) → Run workflow**, which asks for the version
and the track.

## Security notes

- The repo is public, but GitHub never exposes secrets in logs, and never
  gives them to pull requests from forks. A release only runs from a tag on
  `main`, which only you can push.
- The workflow asks for `contents: read` and nothing more.
- The keystore and `key.properties` are deleted at the end of every run, even
  when it fails.
- The service account can reach testing tracks only, so a mistake or a leaked
  key cannot push to production.
- The upload action is pinned to a commit SHA, not a moving tag, so the code
  that handles the signing secrets cannot change under you.

## Worth adding later

- Upload the R8 mapping file and native debug symbols, so Play's crash reports
  come back deobfuscated.
- A release-notes file per track, instead of leaving the notes to Play Console.
