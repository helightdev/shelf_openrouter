import 'package:benchmark/benchmark.dart';
import 'package:spanner/spanner.dart';

class SpannerBenchmark extends RouterBenchmark {

  late Spanner spanner;
  late List<(HTTPMethod method, String path, String expected)> translatedTests;

  @override
  void prepare() {
    spanner = Spanner();
    for (var route in routes) {
      var method = HTTPMethod.values.where((e) => e.name == route.$1).first;
      var shelfFormattedUri = route.$2.split("/").map((e) {
        if (e.startsWith(":")) {
          var id = e.substring(1);
          return "<$id>";
        } else {
          return e;
        }
      }).join("/");
      spanner.addRoute<String>(method, shelfFormattedUri, route.$3);
    }
    translatedTests = tests.map((original) {
      var method = HTTPMethod.values.where((e) => e.name == original.$1).first;
      return (method, original.$2, original.$3);
    }).toList();
  }

  @override
  void run() {
    for (var test in translatedTests) {
      var result = spanner.lookup(test.$1, test.$2);
      continue;
      if (result?.values.firstOrNull != test.$3) {
        throw Exception("Expected ${test.$3} but got ${result?.values} (${test.$1}, ${test.$2})");
      }
    }
  }

}