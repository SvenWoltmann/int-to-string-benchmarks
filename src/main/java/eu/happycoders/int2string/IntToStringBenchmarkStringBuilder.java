package eu.happycoders.int2string;

import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;

import java.util.concurrent.ThreadLocalRandom;

public class IntToStringBenchmarkStringBuilder {

    @State(Scope.Thread)
    public static class MyState {
        public int i;

        @Setup(Level.Invocation)
        public void doSetup() {
            // always 7-digits, so that the String always has the same length
            i = 1_000_000 + ThreadLocalRandom.current().nextInt(9_000_000);
        }
    }

    @Benchmark
    public void integerToString(MyState state, Blackhole blackhole) {
        String s = Integer.toString(state.i);
        blackhole.consume(s);
    }

    @Benchmark
    public void stringPlus(MyState state, Blackhole blackhole) {
        String s = "" + state.i;
        blackhole.consume(s);
    }

    @Benchmark
    public void stringBuilderCapacityDefault(MyState state, Blackhole blackhole) {
        String s = new StringBuilder().append("").append(state.i).toString();
        blackhole.consume(s);
    }

    @Benchmark
    public void stringBuilderCapacity7(MyState state, Blackhole blackhole) {
        String s = new StringBuilder(7).append("").append(state.i).toString();
        blackhole.consume(s);
    }

}
