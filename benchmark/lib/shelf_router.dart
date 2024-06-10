import 'package:benchmark/benchmark.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';

class ShelfRouterBenchmark extends RouterBenchmark {

  ShelfRouter<String> router = ShelfRouter<String>();

  @override
  void prepare() {
    for (var e in routes) {
      var shelfFormattedUri = e.$2.split("/").map((e) {
        if (e.startsWith(":")) {
          var id = e.substring(1);
          return "<$id>";
        } else {
          return e;
        }
      }).join("/");
      router.add(e.$1, shelfFormattedUri, e.$3);
    }
  }

  @override
  void run() {
    for (var e in tests) {
      var result = router.lookup(e.$1, e.$2);
      if (result != e.$3) {
        throw Exception("Expected ${e.$3} but got $result");
      }
    }
  }
}

// Port of shelf router to be benchmarkable under the same conditions without being unfair

/// Check if the [regexp] is non-capturing.
bool _isNoCapture(String regexp) {
  // Construct a new regular expression matching anything containing regexp,
  // then match with empty-string and count number of groups.
  return RegExp('^(?:$regexp)|.*\$').firstMatch('')!.groupCount == 0;
}

class ShelfRouter<T> {

  List<RouterEntry<T>> _routes = [];

  void add(String verb, String route, T value) {
    _routes.add(RouterEntry(verb, route, value));
  }

  T? lookup(String verb, String path) {
    for (var route in _routes) {
      // This will only work with ALL because our tests are properly ordered I guess
      if (route.verb != verb && route.verb != 'ALL') {
        continue;
      }
      var params = route.match(path);
      if (params != null) {
        return route.value;
      }
    }
  }

}

/// Entry in the router.
///
/// This class implements the logic for matching the path pattern.
class RouterEntry<T> {
  /// Pattern for parsing the route pattern
  static final RegExp _parser = RegExp(r'([^<]*)(?:<([^>|]+)(?:\|([^>]*))?>)?');

  final String verb, route;

  final T value;

  /// Expression that the request path must match.
  ///
  /// This also captures any parameters in the route pattern.
  final RegExp _routePattern;

  /// Names for the parameters in the route pattern.
  final List<String> _params;

  /// List of parameter names in the route pattern.
  List<String> get params => _params.toList(); // exposed for using generator.

  RouterEntry._(this.verb, this.route, this.value,
      this._routePattern, this._params);

  factory RouterEntry(String verb,
      String route,
      T value) {

    if (!route.startsWith('/')) {
      throw ArgumentError.value(
          route, 'route', 'expected route to start with a slash');
    }

    final params = <String>[];
    var pattern = '';
    for (var m in _parser.allMatches(route)) {
      pattern += RegExp.escape(m[1]!);
      if (m[2] != null) {
        params.add(m[2]!);
        if (m[3] != null && !_isNoCapture(m[3]!)) {
          throw ArgumentError.value(
              route, 'route', 'expression for "${m[2]}" is capturing');
        }
        pattern += '(${m[3] ?? r'[^/]+'})';
      }
    }
    final routePattern = RegExp('^$pattern\$');

    return RouterEntry._(
        verb, route, value, routePattern, params);
  }

  /// Returns a map from parameter name to value, if the path matches the
  /// route pattern. Otherwise returns null.
  Map<String, String>? match(String path) {
    // Check if path matches the route pattern
    var m = _routePattern.firstMatch(path);
    if (m == null) {
      return null;
    }
    // Construct map from parameter name to matched value
    var params = <String, String>{};
    for (var i = 0; i < _params.length; i++) {
      // first group is always the full match, we ignore this group.
      params[_params[i]] = m[i + 1]!;
    }
    return params;
  }
}