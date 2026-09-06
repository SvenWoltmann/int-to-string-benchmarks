package eu.happycoders.int2string;

import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.Level;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.infra.Blackhole;

import java.util.concurrent.ThreadLocalRandom;

/**
 * Is it the int-to-String conversion or the Formatter itself? Formats a
 * seven-digit number that is already a String, with {@code %s}.
 */
public class FormatterBenchmark {

    @State(Scope.Thread)
    public static class RandomStrings {
        private static final int SIZE = 1024;

        private final String[] values = new String[SIZE];
        private int index;

        @Setup(Level.Trial)
        public void doSetup() {
            ThreadLocalRandom random = ThreadLocalRandom.current();
            for (int k = 0; k < SIZE; k++) {
                values[k] = Integer.toString(1_000_000 + random.nextInt(9_000_000));
            }
        }

        public String next() {
            return values[index++ & (SIZE - 1)];
        }
    }

    @Benchmark
    public void formatter(RandomStrings state, Blackhole blackhole) {
        String s = String.format("%s", state.next());
        blackhole.consume(s);
    }

}
