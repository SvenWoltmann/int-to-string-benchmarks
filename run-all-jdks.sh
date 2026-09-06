#!/usr/bin/env bash
#
# Measures the int-to-String benchmarks across the JDK version series and
# writes one JMH JSON file per JDK and jar to results/.
#
# Three jars, because `"" + i` is the one variant whose bytecode depends on
# the compiler - a StringBuilder chain up to Java 8, an invokedynamic call
# to StringConcatFactory since Java 9:
#
#   jar        built with          methods                       result file
#   matched    javac N, target N   all variants                  java<N>-release<N>.json
#   release8   --release 8         stringPlus + control          java<N>-release8.json
#   release11  --release 11        stringPlus + control          java<N>-release11.json
#
# "matched" is the main series: compiler and JVM as a reader gets them today.
# The other two hold the compiler fixed so that the JVM's share can be read
# off, and carry only stringPlus plus integerToString - the control, whose
# bytecode is identical in every jar, so a difference there is jar-to-jar
# noise, not the compiler. On Java 8 the matched jar *is* the release8 jar,
# so that JDK has a single file.
#
# Usage:
#   ./run-all-jdks.sh [--plan] [--majors 8,11,17,...] [--jars matched,release8,release11]
#
#   --plan     print the schedule (runs, estimated durations, clock times) and stop
#   --majors   restrict the JDK majors (default: 8 11 17 21 22 23 24 25 27)
#   --jars     restrict the jars; the order given is the order of execution
#              (default: matched, then release8, then release11)
#
# JDKs are resolved from the SDKMAN candidates by major version (newest GA
# build, no early access); a missing major is skipped with a message. Every
# run uses 3 forks x (5 warmup + 5 measurement) x 5 s per method, the GC
# profiler (bytes per operation), and the blackhole mode pinned with
# -Djmh.blackhole.autoDetect=false, so that every JDK measures with the same
# blackhole instead of the cheaper compiler blackhole JMH picks on 17+.
# Expect about 2.7 minutes per method and JDK.

set -euo pipefail

MAJORS=(8 11 17 21 22 23 24 25 27)
JARS=(matched release8 release11)
PLAN=0

# JMH_OPTS in the environment overrides these, e.g. for a smoke test of the
# script: JMH_OPTS="-f 1 -wi 1 -i 1 -w 1 -r 1" ./run-all-jdks.sh --majors 25
read -r -a JMH_OPTS <<< "${JMH_OPTS:--f 3 -wi 5 -i 5 -w 5 -r 5 -prof gc}"
MINUTES_PER_METHOD=2.7   # 3 x (25 + 25) s plus JVM start and the profiler
MINUTES_PER_BUILD=0.5

# Package-qualified, so that the gitignored experiment classes in a local
# checkout (eu.happycoders.int2string.gitignore.*) never match.
MATCHED_FILTERS=('eu\.happycoders\.int2string\.IntToStringBenchmark\.'
                 'eu\.happycoders\.int2string\.IntToStringBenchmarkStringBuilder\.stringBuilderCapacityDefault$')
MATCHED_METHODS=5
DIAG_FILTERS=('eu\.happycoders\.int2string\.IntToStringBenchmarkStringBuilder\.(stringPlus|integerToString)$')
DIAG_METHODS=2

SDKMAN_JAVA="${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan) PLAN=1 ;;
    --majors) IFS=', ' read -r -a MAJORS <<< "$2"; shift ;;
    --jars) IFS=', ' read -r -a JARS <<< "$2"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

cd "$(dirname "$0")"

# Newest installed SDKMAN candidate for a major version, e.g. 21 -> 21.0.2-open.
# Early-access and vendor-specific builds are skipped: a version series is only
# comparable when every entry is a GA build. `|| true`: grep exits 1 when
# nothing matches, and under `set -eo pipefail` that would abort the whole
# script instead of skipping the missing major.
resolve_jdk() {
  local major="$1"
  ls -1 "$SDKMAN_JAVA" 2>/dev/null \
    | grep -E "^${major}(\.[0-9]+)*-(open|zulu|tem|oracle)$" \
    | sort -V | tail -1 || true
}

# The JDK that builds the release8 and release11 jars: the newest one
# installed. Which one it is does not matter for the bytecode (--release
# pins it), only Maven's plugins have to run on it.
build_jdk() {
  local major
  for major in 27 26 25 24 23 22 21 17; do
    local v; v="$(resolve_jdk "$major")"
    if [[ -n "$v" ]]; then echo "$v"; return; fi
  done
  echo "No JDK >= 17 installed to build with" >&2
  exit 1
}

clock() { date -r "$1" +%H:%M 2>/dev/null || date -d "@$1" +%H:%M; }

# --- plan the runs ---------------------------------------------------------
# One entry per run: major|jar|release|methods|outfile
RUNS=()
NEEDED_JARS=()   # "release|java_home" pairs, deduplicated
need_jar() {
  local entry="$1|$2"
  local n; for n in "${NEEDED_JARS[@]:-}"; do [[ "$n" == "$entry" ]] && return; done
  NEEDED_JARS+=("$entry")
}

# Resolved once; plain lines "major version", because macOS ships bash 3.2
# without associative arrays.
RESOLVED=""
for major in "${MAJORS[@]}"; do
  v="$(resolve_jdk "$major")"
  if [[ -z "$v" ]]; then
    echo "SKIP Java $major - no GA build installed (sdk list java | grep '^ *$major')" >&2
  else
    RESOLVED+="$major $v"$'\n'
  fi
done
version_of() { printf '%s' "$RESOLVED" | awk -v m="$1" '$1 == m {print $2}'; }

BUILD_JDK="$(build_jdk)"
for jar in "${JARS[@]}"; do
  for major in "${MAJORS[@]}"; do
    [[ -z "$(version_of "$major")" ]] && continue
    case "$jar" in
      matched)
        if (( major == 8 )); then
          need_jar 8 "$SDKMAN_JAVA/$BUILD_JDK"
          RUNS+=("$major|matched|8|$MATCHED_METHODS|results/java${major}-release8")
        else
          need_jar "$major" "$SDKMAN_JAVA/$(version_of "$major")"
          RUNS+=("$major|matched|$major|$MATCHED_METHODS|results/java${major}-release${major}")
        fi ;;
      release8)
        (( major >= 11 )) || continue
        need_jar 8 "$SDKMAN_JAVA/$BUILD_JDK"
        RUNS+=("$major|release8|8|$DIAG_METHODS|results/java${major}-release8") ;;
      release11)
        (( major >= 17 )) || continue
        need_jar 11 "$SDKMAN_JAVA/$BUILD_JDK"
        RUNS+=("$major|release11|11|$DIAG_METHODS|results/java${major}-release11") ;;
      *) echo "unknown jar: $jar (matched, release8, release11)" >&2; exit 2 ;;
    esac
  done
done

# --- print the schedule ----------------------------------------------------
now=$(date +%s)
t=$now
build_minutes=$(awk -v n="${#NEEDED_JARS[@]}" -v m="$MINUTES_PER_BUILD" 'BEGIN{print n*m}')
t=$(awk -v t="$t" -v m="$build_minutes" 'BEGIN{printf "%d", t + m*60}')
printf "%-6s %-10s %-8s %-30s %6s  %5s  %5s\n" JDK jar methods "result" min start end
printf "%-6s %-10s %-8s %-30s %6s  %5s  %5s\n" - "${#NEEDED_JARS[@]} builds" - - "$build_minutes" "$(clock "$now")" "$(clock "$t")"
for run in "${RUNS[@]}"; do
  IFS='|' read -r major jar release methods out <<< "$run"
  minutes=$(awk -v n="$methods" -v m="$MINUTES_PER_METHOD" 'BEGIN{print n*m}')
  start=$t
  t=$(awk -v t="$t" -v m="$minutes" 'BEGIN{printf "%d", t + m*60}')
  printf "%-6s %-10s %-8s %-30s %6s  %5s  %5s\n" "$major" "$jar" "$methods" "$out.json" "$minutes" "$(clock "$start")" "$(clock "$t")"
done
total=$(awk -v a="$now" -v b="$t" 'BEGIN{printf "%.1f", (b-a)/60}')
echo "Total: ${#RUNS[@]} runs, about $total minutes, done around $(clock "$t")."
(( PLAN )) && exit 0

# --- build the jars --------------------------------------------------------
mkdir -p jars results
for entry in "${NEEDED_JARS[@]}"; do
  IFS='|' read -r release home <<< "$entry"
  echo "=== Building jars/benchmarks-release${release}.jar with $(basename "$home") ..."
  JAVA_HOME="$home" mvn -q -B clean package -Dmaven.compiler.release="$release"
  cp "target/benchmarks-release${release}.jar" "jars/"
done

# --- run -------------------------------------------------------------------
for run in "${RUNS[@]}"; do
  IFS='|' read -r major jar release methods out <<< "$run"
  version="$(version_of "$major")"
  java_bin="$SDKMAN_JAVA/$version/bin/java"
  if [[ "$jar" == matched ]]; then filters=("${MATCHED_FILTERS[@]}"); else filters=("${DIAG_FILTERS[@]}"); fi
  echo
  echo "=== $(date +%H:%M) Java $major ($version), jar $jar -> $out.json"
  "$java_bin" -Djmh.blackhole.autoDetect=false -jar "jars/benchmarks-release${release}.jar" \
    "${filters[@]}" "${JMH_OPTS[@]}" -rf json -rff "$out.json" \
    | tee "$out.txt"
done

echo
echo "Done at $(date +%H:%M). JSON results in results/, human-readable logs next to them."
