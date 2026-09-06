package eu.happycoders.int2string;

import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.infra.Blackhole;

/**
 * {@code "" + i} against the StringBuilder chain javac emitted for it up to
 * Java 8, and {@code Integer.toString()} as the control whose bytecode is the
 * same in every jar.
 */
public class IntToStringBenchmarkStringBuilder {

    @Benchmark
    public void integerToString(RandomInts state, Blackhole blackhole) {
        String s = Integer.toString(state.next());
        blackhole.consume(s);
    }

    @Benchmark
    public void stringPlus(RandomInts state, Blackhole blackhole) {
        String s = "" + state.next();
        blackhole.consume(s);
    }

    @Benchmark
    public void stringBuilderCapacityDefault(RandomInts state, Blackhole blackhole) {
        String s = new StringBuilder().append("").append(state.next()).toString();
        blackhole.consume(s);
    }

    @Benchmark
    public void stringBuilderCapacity7(RandomInts state, Blackhole blackhole) {
        String s = new StringBuilder(7).append("").append(state.next()).toString();
        blackhole.consume(s);
    }

}
