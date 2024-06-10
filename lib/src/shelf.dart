import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_openrouter/shelf_openrouter.dart';

/// Middleware to remove body from request.
final _removeBody = createMiddleware(responseHandler: (r) {
  if (r.headers.containsKey('content-length')) {
    r = r.change(headers: {'content-length': '0'});
  }
  return r.change(body: <int>[]);
});

/// Http router that can be integrated with shelf which internally uses [OpenRouter].
class ShelfOpenRouter {
  static final Response routeNotFound = _RouteNotFoundResponse();
  static Response _defaultNotFound(Request request) => routeNotFound;

  final OpenRouter<ShelfOpenRouterEntry> _router = OpenRouter();

  /// Http router that can be integrated with shelf which internally uses [OpenRouter].
  ShelfOpenRouter() {
    _router.addRoute([], "CATCHALL", ShelfOpenRouterEntry(_defaultNotFound));
  }

  List<RouterEntry<ShelfOpenRouterEntry>> get routes => _router.routes;

  /// Adds a new route to the router.
  /// {@template openrouter.shelfhandler}
  /// ### Handler Function
  /// The handler function should conform to a normal [Handler] function signature,
  /// if no path parameters are defined. If path parameters are defined, the handler
  /// function should accept as many additional String parameters as there are path
  /// parameters.
  /// ```dart
  /// router.get("/hello/world", (Request request) {
  /// ```
  /// ```dart
  /// router.get("/hello/:name", (Request request, String name) {
  /// ```
  /// {@endtemplate}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void add(String verb, String path, Function handler) {
    if (path.startsWith("/")) {
      path = path.substring(1);
    }
    var pathSegments = path.split("/");
    verb = verb.toUpperCase();
    if (verb == "GET") {
      _router.addRoute(pathSegments, "HEAD", ShelfOpenRouterEntry(handler, middleware: _removeBody));
    }
    _router.addRoute(pathSegments, verb, ShelfOpenRouterEntry(handler));
  }

  /// Adds a new GET route to the router.
  /// This also automatically registers a HEAD route for the same path.
  ///
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void get(String path, Function handler) => add("GET", path, handler);

  /// Adds a new POST route to the router.
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void post(String path, Function handler) => add("POST", path, handler);

  /// Adds a new PUT route to the router.
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void put(String path, Function handler) => add("PUT", path, handler);

  /// Adds a new DELETE route to the router.
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void delete(String path, Function handler) => add("DELETE", path, handler);

  /// Adds a new PATCH route to the router.
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void patch(String path, Function handler) => add("PATCH", path, handler);

  /// Adds a new OPTIONS route to the router.
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void options(String path, Function handler) => add("OPTIONS", path, handler);

  /// Adds a new TRACE route to the router.
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void trace(String path, Function handler) => add("TRACE", path, handler);

  /// Adds a new CONNECT route to the router.
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void connect(String path, Function handler) => add("CONNECT", path, handler);

  /// Adds a new route to the router for all HTTP verbs.
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void all(String path, Function handler) => add("ALL", path, handler);

  /// Adds a new route to the router for all paths and verbs starting at the given path.
  /// {@macro openrouter.shelfhandler}
  /// {@macro openrouter.pathvariables}
  /// {@macro openrouter.precedence}
  void catchall(String path, Function handler) => add("CATCHALL", path, handler);

  /// Calls the router with the given request.
  /// This method is used to integrate the router with a shelf server.
  Future<Response> call(Request request) async {
    var pathSegments = request.url.pathSegments;
    var verb = request.method.toUpperCase();
    var params = <String>[];
    var entry = _router.lookup(pathSegments, verb, params);
    if (entry == null) {
      return Response.notFound("Not Found");
    }
    return await entry.invoke(request, params);
  }

}


/// Contains the handler function and middleware for a route.
class ShelfOpenRouterEntry {
  final Function _handler;
  final Middleware _middleware;
  ShelfOpenRouterEntry._(this._handler, this._middleware);

  factory ShelfOpenRouterEntry(Function handler, {Middleware? middleware}) {
    middleware ??= ((Handler fn) => fn);
    return ShelfOpenRouterEntry._(handler, middleware);
  }

  Future<Response> invoke(Request request, List<String> pathParams) async {
    request = request.change(context: {'shelf_openrouter/pathParams': pathParams});

    return await _middleware((request) async {
      if (_handler is Handler || pathParams.isEmpty) {
        // ignore: avoid_dynamic_calls
        return await _handler(request) as Response;
      }
      return await Function.apply(_handler, [
        request,
        ...pathParams,
      ]) as Response;
    })(request);
  }
}


class _RouteNotFoundResponse extends Response {
  static const _message = 'Route not found';
  static final _messageBytes = utf8.encode(_message);

  _RouteNotFoundResponse() : super.notFound(_message);

  @override
  Stream<List<int>> read() => Stream<List<int>>.value(_messageBytes);

  @override
  Response change({
    Map<String, /* String | List<String> */ Object?>? headers,
    Map<String, Object?>? context,
    Object? body,
  }) {
    return super.change(
      headers: headers,
      context: context,
      body: body ?? _message,
    );
  }
}