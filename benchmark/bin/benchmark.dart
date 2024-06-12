import 'package:benchmark/alfred.dart';
import 'package:benchmark/benchmark.dart' as benchmark;
import 'package:benchmark/openrouter.dart';
import 'package:benchmark/routingkit.dart';
import 'package:benchmark/shelf_router.dart';
import 'package:benchmark/spanner.dart';

void main(List<String> arguments) {
  var count = 1000000;
  runBenchmark(AlfredBenchmark(), "Alfred", count);
  runBenchmark(SpannerBenchmark(), "Spanner", count);
  runBenchmark(ShelfRouterBenchmark(), "ShelfRouter", count);
  runBenchmark(RoutingkitBenchmark(), "Routingkit", count);
  runBenchmark(OpenrouterBenchmark(), "OpenRouter", count);
}


void runBenchmark(benchmark.RouterBenchmark benchmark, String name, int count) {
  benchmark.prepare();
  // Warmup
  for (var i = 0; i < count * 0.5; i++) {
    benchmark.run();
  }
  var stopwatch = Stopwatch()..start();
  for (var i = 0; i < count; i++) {
    benchmark.run();
  }
  stopwatch.stop();
  print("$name Time: ${stopwatch.elapsedMilliseconds} ms");
}