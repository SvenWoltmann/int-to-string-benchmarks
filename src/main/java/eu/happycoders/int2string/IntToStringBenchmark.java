package eu.happycoders.int2string;

import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;

import java.util.concurrent.ThreadLocalRandom;

public class IntToStringBenchmark {

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
    public void option1(MyState state, Blackhole blackhole) {
        String s = Integer.toString(state.i);
        blackhole.consume(s);
    }

    @Benchmark
    public void option2(MyState state, Blackhole blackhole) {
        String s = String.valueOf(state.i);
        blackhole.consume(s);
    }

    @Benchmark
    public void option3(MyState state, Blackhole blackhole) {
        String s = String.format("%d", state.i);
        blackhole.consume(s);
    }

    @Benchmark
    public void option4(MyState state, Blackhole blackhole) {
        String s = "" + state.i;
        blackhole.consume(s);
    }

}
