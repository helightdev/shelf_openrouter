import 'package:benchmark/benchmark.dart';
import 'package:routingkit/routingkit.dart';

class RoutingkitBenchmark extends RouterBenchmark {
  TrieRouter<Map<String,String>> router = TrieRouter();

  @override
  void prepare() {
    var equivalentPaths = routes.map((e) => e.$2).toSet();
    for (var e in equivalentPaths) {
      var allVerbRoutes = routes.where((r) => r.$2 == e).toList();
      var verbMap = <String, String>{};
      for (var r in allVerbRoutes) {
        verbMap[r.$1] = r.$3;
      }
      router.register(verbMap, e.asSegments);
    }
  }

  @override
  void run() {
    for (var e in tests) {
      var resultMap = router.lookup(e.$2.asPaths,  Params());
      if (resultMap == null) {
        throw Exception("Expected ${e.$3} but got null");
      }
      var result = resultMap[e.$1];
      if (result == null && resultMap.containsKey("ALL")) {
        result = resultMap["ALL"];
      }
      if (result != e.$3) {
        throw Exception("Expected ${e.$3} but got $result");
      }
    }
  }
}