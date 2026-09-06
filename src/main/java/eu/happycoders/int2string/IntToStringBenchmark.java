package eu.happycoders.int2string;

import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.infra.Blackhole;

public class IntToStringBenchmark {

    @Benchmark
    public void option1(RandomInts state, Blackhole blackhole) {
        String s = Integer.toString(state.next());
        blackhole.consume(s);
    }

    @Benchmark
    public void option2(RandomInts state, Blackhole blackhole) {
        String s = String.valueOf(state.next());
        blackhole.consume(s);
    }

    @Benchmark
    public void option3(RandomInts state, Blackhole blackhole) {
        String s = String.format("%d", state.next());
        blackhole.consume(s);
    }

    @Benchmark
    public void option4(RandomInts state, Blackhole blackhole) {
        String s = "" + state.next();
        blackhole.consume(s);
    }

}
