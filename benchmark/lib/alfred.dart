import 'dart:async';

import 'package:alfred/alfred.dart';
import 'package:benchmark/benchmark.dart';

class AlfredBenchmark extends RouterBenchmark with Router {

  final alfredRoutes = <HttpRoute>[];
  late List<(Method method, String path, String expected)> translatedTests;

  @override
  void prepare() {
    for (var route in routes) {
      var method = Method.values.where((e) => e.name == route.$1.toLowerCase()).first;
      alfredRoutes.add(HttpRoute(method, route.$2, route.$3));
    }

    translatedTests = tests.map((original) {
      var method = Method.values.where((e) => e.name == original.$1.toLowerCase()).first;
      return (method, original.$2, original.$3);
    }).toList();
  }

  @override
  void run() {
    for (var test in translatedTests) {
      var result = RouteMatcher.match(test.$2, alfredRoutes, test.$1).firstOrNull;
      if (result?.route.value != test.$3) {
        throw Exception("Expected ${test.$3} but got ${result?.route.value} (${test.$1}, ${test.$2})");
      }
    }
  }

  @override
  Alfred get app => throw UnimplementedError();

  @override
  String get pathPrefix => "";

}

// -- Copied classes from alfred, modified for the benchmark

class RouteMatcher {
  static Iterable<HttpRouteMatch> match(
      String input, List<HttpRoute> options, Method method) sync* {
    // decode URL path before matching except for "/"
    final inputPath =
    Uri.parse(input).path.normalizePath.decodeUri(DecodeMode.AllButSlash);

    for (final option in options) {
      // Check if http method matches
      if (option.method != method && option.method != Method.all) {
        continue;
      }

      // Match against route RegExp and capture params if valid
      final match = option.matcher.firstMatch(inputPath);
      if (match != null) {
        final routeMatch = HttpRouteMatch.tryParse(option, match);
        if (routeMatch != null) {
          yield routeMatch;
        }
      }
    }
  }
}

/// Retains the matched route and parameter values extracted
/// from the Uri
///
class HttpRouteMatch {
  HttpRouteMatch._(this.route, this.params);

  static HttpRouteMatch? tryParse(HttpRoute route, RegExpMatch match) {
    try {
      final params = <String, dynamic>{};
      for (var param in route.params) {
        var value = match.namedGroup(param.name);
        if (value == null) {
          if (param.pattern != '*') {
            return null;
          }
          value = '';
        }
        params[param.name] = param.getValue(value);
      }
      return HttpRouteMatch._(route, params);
    } catch (e) {
      return null;
    }
  }

  final HttpRoute route;
  final Map<String, dynamic> params;
}

class HttpRoute {
  final Method method;
  final String route;
  final String value;

  // The RegExp used to match the input URI
  late final RegExp matcher;

  // Returns `true` if route can match multiple routes due to usage of
  // wildcards (`*`)
  final bool usesWildcardMatcher;

  // The route parameters (name, type and pattern)
  final Map<String, HttpRouteParam> _params = <String, HttpRouteParam>{};

  Iterable<HttpRouteParam> get params => _params.values;

  HttpRoute(this.method, this.route, this.value)
      : usesWildcardMatcher = route.contains('*') {
    // Split route path into segments

    /// Because in dart 2.18 uri parsing is more permissive, using a \ in regex
    /// is being counted as a /, so we need to add an r and join them together
    /// VERY happy for a more elegant solution here than some random escape
    /// sequence.
    const escapeChar = '@@@^';
    var escapedPath = route.normalizePath.replaceAll('\\', escapeChar);
    var segments =
        Uri.tryParse('/${escapedPath}')?.pathSegments ?? [route.normalizePath];
    segments = segments.map((e) => e.replaceAll(escapeChar, '\\')).toList();

    var pattern = '^';
    for (var segment in segments) {
      if (segment == '*' &&
          segment != segments.first &&
          segment == segments.last) {
        // Generously match path if last segment is wildcard (*)
        // Example: 'some/path/*' => should match 'some/path', 'some/path/', 'some/path/with/children'
        //                           but not 'some/pathological'
        pattern += r'(?:/.*|)';
        break;
      } else if (segment != segments.first) {
        // Add path separators
        pattern += '/';
      }

      // parse parameter if any
      final param = HttpRouteParam.tryParse(segment);
      if (param != null) {
        if (_params.containsKey(param.name)) {
          throw DuplicateParameterException(param.name);
        }
        _params[param.name] = param;
        // ignore: prefer_interpolation_to_compose_strings
        segment = r'(?<' + param.name + r'>' + param.pattern + ')';
      } else {
        // escape period character
        segment = segment.replaceAll('.', r'\.');
        // wildcard ('*') to anything
        segment = segment.replaceAll('*', '.*?');
      }

      pattern += segment;
    }

    pattern += r'$';
    matcher = RegExp(pattern, caseSensitive: false);
  }

  @override
  String toString() => route;
}

/// Throws when a route contains duplicate parameters
///
class DuplicateParameterException implements Exception {
  DuplicateParameterException(this.name);

  final String name;
}

/// Class used to retain parameter information (name, type, pattern)
///
class HttpRouteParam {
  HttpRouteParam(this.name, this.pattern, this.type);

  final String name;
  final String pattern;
  final HttpRouteParamType? type;

  dynamic getValue(String value) {
    // path has been decoded already except for '/'
    value = value.decodeUri(DecodeMode.SlashOnly);
    return type?.parse(value) ?? value;
  }

  static final paramTypes = <HttpRouteParamType>[];

  static HttpRouteParam? tryParse(String segment) {
    /// route param is of the form ":name" or ":name:pattern"
    /// the ":pattern" part can be a regular expression
    /// or a param type name
    if (!segment.startsWith(':')) return null;
    var pattern = '';
    var name = segment.substring(1);
    HttpRouteParamType? type;
    final idx = name.indexOf(':');
    if (idx > 0) {
      pattern = name.substring(idx + 1);
      name = name.substring(0, idx);
      final typeName = pattern.toLowerCase();
      type = paramTypes
          .cast<HttpRouteParamType?>()
          .firstWhere((t) => t!.name == typeName, orElse: () => null);
      if (type != null) {
        // the pattern matches a param type name
        pattern = type.pattern;
      }
    } else {
      // anything but a slash
      pattern = r'[^/]+?';
    }
    return HttpRouteParam(name, pattern, type);
  }
}