#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
STUBS="$BUILD/generated-stubs"

rm -rf "$BUILD"
mkdir -p "$BUILD/classes" "$BUILD/stub-classes"
"$ROOT/dev/generate-stubs.sh" "$STUBS"
"$ROOT/dev/patch-stubs-for-source.sh" "$STUBS"

find "$STUBS" -name '*.java' -print0 | xargs -0 javac --release 17 -d "$BUILD/stub-classes"
find "$ROOT/src/main/java" -name '*.java' -print0 | xargs -0 javac --release 17 -cp "$BUILD/stub-classes" -d "$BUILD/classes"
cp -R "$ROOT/src/main/resources/." "$BUILD/classes/"

jar --create \
  --file "$BUILD/hostile-mob-health-multiplier-1.0.3.jar" \
  -C "$BUILD/classes" . \
  -C "$ROOT" LICENSE

printf 'Built %s\n' "$BUILD/hostile-mob-health-multiplier-1.0.3.jar"
