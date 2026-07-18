#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
"$ROOT/build.sh"
mkdir -p "$ROOT/build/test"

javac --release 17 \
  -cp "$ROOT/build/stub-classes:$ROOT/build/classes" \
  -d "$ROOT/build/test" \
  "$ROOT/test/TestHarness.java"

(
  cd "$ROOT/build/test"
  java -cp "$ROOT/build/stub-classes:$ROOT/build/classes:$ROOT/build/test" TestHarness
)
