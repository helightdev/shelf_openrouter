import 'package:benchmark/benchmark.dart';
import 'package:shelf_openrouter/shelf_openrouter.dart';

class OpenrouterBenchmark extends RouterBenchmark {
  OpenRouter<String> router = OpenRouter<String>();

  @override
  void prepare() {
    for (var e in routes) {
      var routeString = e.$2;
      if (routeString.startsWith("/")) {
        routeString = routeString.substring(1);
      }
      router.addRoute(routeString.split("/"), e.$1, e.$3);
    }
  }

  @override
  void run() {
    for (var e in tests) {
      var str = e.$2;
      if (str.startsWith("/")) {
        str = str.substring(1);
      }
      var result = router.lookup(str.split("/"), e.$1, []);
      if (result != e.$3) {
        throw Exception("Expected ${e.$3} but got $result");
      }
    }
  }
}