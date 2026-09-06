# Benchmark results

## 2026-09 (`2026-09/`)

The series behind the current version of the article: Java 8, 11, 17,
21, 22, 23, 24 and 25 on two machines, one directory per machine
(`machine.json` describes the hardware). Java 17 is Temurin 17.0.20 on arm64
and 17.0.2 on x86. JMH JSON with the primary
metric, the error interval (99.9 %), every fork's iterations, and the
GC profiler's bytes per operation.

File names: `java<N>-release<M>.json` is JVM `N` running the jar built
with bytecode level `M`.

- `java<N>-release<N>.json` – compiler and JVM of the same version, all
  variants. The main series.
- `java<N>-release8.json` – the `--release 8` jar (StringBuilder chain
  for `"" + i`) on JVM `N`, only `stringPlus` and the control
  `integerToString`.
- `java<N>-release11.json` – the `--release 11` jar (indified
  concatenation, compiler held at 11) on JVM `N`, same two methods.

Measured with the `Level.Trial` input state (`RandomInts`), three forks
of five warm-up and five measurement iterations of five seconds each,
and the blackhole mode pinned (`-Djmh.blackhole.autoDetect=false`) -
see `run-all-jdks.sh`.

## 2019 (`results_java*.txt`)

The measurements of the article's first version: Java 7, 8, 9, 11, 13
and 14 on a Dell XPS 15 (i7-8750H). They used a per-invocation JMH
state (`@Setup(Level.Invocation)`), which for a nanosecond operation
measures the timestamps more than the conversion. Kept as the
historical record; do not compare them with the 2026 numbers.
