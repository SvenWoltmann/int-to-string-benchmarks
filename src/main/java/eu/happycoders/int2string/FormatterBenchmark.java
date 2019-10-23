package eu.happycoders.int2string;

import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;

import java.util.concurrent.ThreadLocalRandom;

public class FormatterBenchmark {

    @State(Scope.Thread)
    public static class MyState {
        public String s;

        @Setup(Level.Invocation)
        public void doSetup() {
            // always 7-digits, so that the String always has the same length
            s = "" + 1_000_000 + ThreadLocalRandom.current().nextInt(9_000_000);
        }
    }

    @Benchmark
    public void formatter(MyState state, Blackhole blackhole) {
        String s = String.format("%s", state.s);
        blackhole.consume(s);
    }

}
