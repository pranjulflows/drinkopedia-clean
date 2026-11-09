#!/usr/bin/env bash
#
# Runs a Flutter command, retrying it only when it failed on a corrupted
# native-asset download.
#
# package:sqlite3, which drift depends on, downloads a prebuilt libsqlite3
# from GitHub releases and checks it against a hash baked into the package.
# On GitHub's runners that download intermittently hands back a different
# file and the build stops with "Hash of downloaded file ... is ..., expected
# ...". The release asset itself is fine — fetched by hand it matches every
# time, and the bad copy is neither a sibling asset nor an error page — so the
# answer is to ask for it again rather than to change the dependency.
#
# Everything else, a genuine test failure included, fails immediately: a retry
# loop that swallowed real failures would be worse than the flake.
set -uo pipefail

readonly attempts=4
readonly marker='Hash of downloaded file'
log=$(mktemp)
trap 'rm -f "$log"' EXIT

for attempt in $(seq 1 "$attempts"); do
  if "$@" 2>&1 | tee "$log"; then
    exit 0
  fi

  if ! grep -q "$marker" "$log"; then
    exit 1
  fi

  if [ "$attempt" -lt "$attempts" ]; then
    echo "::warning::Native asset download came back corrupt (attempt $attempt of $attempts) — retrying"
    sleep $((attempt * 10))
  fi
done

echo "::error::Native asset download stayed corrupt after $attempts attempts."
echo "::error::This is the flaky sqlite3 download, not a test failure. Re-run the job."
exit 1
