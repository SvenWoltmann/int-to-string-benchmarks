#!/usr/bin/env bash
#
# Runs the benchmarks of this repository on every JDK of the version series
# and writes one JMH JSON file per JDK to results/.
#
# The jar is built once (with --release 8) and then run unchanged on every
# JDK, so the bytecode is not a variable in the measurement.
#
# Usage:
#   ./run-all-jdks.sh [benchmark-filter]
#
# JDKs are picked from the SDKMAN candidates by major version, so a new patch
# release does not need an edit here - only a new major does. Expect roughly
# 8.5 minutes per benchmark method and JDK (JMH defaults: 5 forks x (5 warmup
# + 5 measurement) x 10 s), so let the machine idle while this runs.

set -euo pipefail

MAJORS=(8 11 17 21 25 27)

FILTER="${1:-}"
SDKMAN_JAVA="${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java"
JAR="target/benchmarks.jar"

cd "$(dirname "$0")"

# Newest installed SDKMAN candidate for a major version, e.g. 21 -> 21.0.2-open.
# Early-access and vendor-specific builds are skipped: a version series is only
# comparable when every entry is a GA build.
resolve_jdk() {
  local major="$1"
  ls -1 "$SDKMAN_JAVA" 2>/dev/null \
    | grep -E "^${major}(\.[0-9]+)*-(open|zulu|tem|oracle)$" \
    | sort -V | tail -1
}

echo "Building $JAR ..."
mvn -q -B clean package

mkdir -p results

for major in "${MAJORS[@]}"; do
  version="$(resolve_jdk "$major")"
  if [[ -z "$version" ]]; then
    echo "SKIP Java $major - no GA build installed (sdk list java | grep '^ *$major')" >&2
    continue
  fi

  java_bin="$SDKMAN_JAVA/$version/bin/java"
  out="results/java${major}"

  echo "=== Java $major ($version) -> $out.json"
  "$java_bin" -jar "$JAR" ${FILTER:+"$FILTER"} -rf json -rff "$out.json" \
    | tee "$out.txt"
done

echo
echo "Done. JSON results in results/, human-readable logs next to them."
