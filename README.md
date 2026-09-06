# How to convert int to String in Java – the fastest way

JMH benchmarks to find out what is the fastest way to convert an int into a String in Java.

Related article on my blog:
* English: [How to convert int to String in Java – the fastest way](https://www.happycoders.eu/java/how-to-convert-int-to-string-fastest/)
* German: [Java: int in String umwandeln – der schnellste Weg](https://www.happycoders.eu/de/java/int-in-string-umwandeln-schnellster-weg/)

## Running the series

```
./run-all-jdks.sh --plan   # what would run, with estimated clock times
./run-all-jdks.sh          # the whole series
```

The script resolves the JDKs (8, 11, 17, 21, 22, 23, 24, 25, 27) from the
SDKMAN candidates and skips the ones that are not installed. It builds three
jars, because `"" + i` is the one variant whose bytecode depends on the
compiler – a `StringBuilder` chain up to Java 8, an `invokedynamic` call to
`StringConcatFactory` since Java 9:

| Jar | Built with | Methods | Result file |
|---|---|---|---|
| matched | javac N, target N | all variants | `results/java<N>-release<N>.json` |
| release8 | `--release 8` | `stringPlus` + control | `results/java<N>-release8.json` |
| release11 | `--release 11` | `stringPlus` + control | `results/java<N>-release11.json` |

*matched* is the main series: compiler and JVM as you get them today. The
other two hold the compiler fixed, so that the JVM's share of a change can be
read off; they carry only `stringPlus` and `integerToString` as the control
whose bytecode is identical in every jar. On Java 8 the matched jar *is* the
release8 jar.

Every run uses 3 forks × (5 warmup + 5 measurement) × 5 s per method, JMH's
GC profiler (bytes per operation), and `-Djmh.blackhole.autoDetect=false`, so
that every JDK measures with the same blackhole. `--majors` and `--jars`
restrict a run; `JMH_OPTS` in the environment overrides the JMH settings.

## The 2019 results

`results/results_java*.txt` are the measurements the article was originally
based on (Java 7 to 14, Dell XPS 15 with an i7-8750H). They were taken with a
`@Setup(Level.Invocation)` state, which JMH documents as unusable for
sub-millisecond operations: it timestamps every invocation, so a 5–20 ns
conversion was measured together with two `System.nanoTime()` calls. The
benchmarks now draw their input once per trial (`RandomInts`), and the
current measurements live with the article's other data in the website
repository.

Happy Coding!
