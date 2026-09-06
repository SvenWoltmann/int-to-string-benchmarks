package eu.happycoders.int2string;

import org.openjdk.jmh.annotations.Level;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.State;

import java.util.concurrent.ThreadLocalRandom;

/**
 * The input of every int-to-String benchmark: 1024 random seven-digit
 * numbers, drawn once per trial and handed out round-robin.
 *
 * <p>Seven digits, so that every String has the same length. Drawn once per
 * trial and not per invocation: with {@code @Setup(Level.Invocation)} JMH has
 * to timestamp every single call to subtract the setup time, and for an
 * operation of 5–20 ns that measures the clock more than the conversion (on
 * Apple Silicon {@code System.nanoTime()} ticks in 41 ns steps). The 2019
 * numbers were measured that way; see the README.
 */
@State(Scope.Thread)
public class RandomInts {

    private static final int SIZE = 1024;

    private final int[] values = new int[SIZE];
    private int index;

    @Setup(Level.Trial)
    public void doSetup() {
        ThreadLocalRandom random = ThreadLocalRandom.current();
        for (int k = 0; k < SIZE; k++) {
            values[k] = 1_000_000 + random.nextInt(9_000_000);
        }
    }

    public int next() {
        return values[index++ & (SIZE - 1)];
    }

}
