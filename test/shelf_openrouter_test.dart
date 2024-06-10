import 'package:shelf_openrouter/shelf_openrouter.dart';
import 'package:test/test.dart';

void main() {
  group('Route Matching test', () {
    test('Simple Test', () {
      var router = OpenRouter<String>();
      router.addRoute(["a", "b", "c"], "GET", "Hello");
      router.addRoute(["a", "b", "d"], "GET", "World");
      router.addRoute(["a", "b", ":id"], "GET", "Wildcard");
      router.addRoute(["a", ":id"], "GET", "Wildcard2");

      expect(router.lookup(["a", "b", "c"], "GET", []), "Hello");
      expect(router.lookup(["a", "b", "d"], "GET", []), "World");
      expect(router.lookup(["a", "b", "e"], "GET", []), "Wildcard");
      expect(router.lookup(["a", "f"], "GET", []), "Wildcard2");

      var allRoutes = router.routes;
      expect(allRoutes.length, 4);
    });

    test('Wildcard Test', () {
      var router = OpenRouter<String>();
      router.addRoute(["a", "b", ":id"], "GET", "Wildcard");
      var buffer = <String>[];
      expect(router.lookup(["a", "b", "c"], "GET", buffer), "Wildcard");
      expect(buffer, ["c"]);
    });

    test('Verb All Fallback', () {
      var router = OpenRouter<String>();
      router.addRoute(["a", "b"], "ALL", "All");
      router.addRoute(["a", "b"], "POST", "Post");
      expect(router.lookup(["a", "b"], "GET", []), "All");
      expect(router.lookup(["a", "b"], "POST", []), "Post");
      var allRoutes = router.routes;
      expect(allRoutes.length, 2);
    });

    test('Invalid Route', () {
      var router = OpenRouter<String>();
      router.addRoute(["a", "b"], "GET", "Hello");
      expect(router.lookup(["a", "c"], "GET", []), null);
      expect(router.lookup(["a"], "GET", []), null);
    });

    test('Catch All', () {
      var router = OpenRouter<String>();
      router.addRoute(["a", "b"], "CATCHALL", "Catch All 1");
      router.addRoute(["a"], "CATCHALL", "Catch All 2");
      router.addRoute(["a", "b", "c"], "GET", "Not Catch All");
      expect(router.lookup(["a", "b", "c"], "GET", []), "Not Catch All");
      expect(router.lookup(["a", "b", "c"], "POST", []), "Catch All 1");
      expect(router.lookup(["a", "b", "c", "d"], "GET", []), "Catch All 1");
      expect(router.lookup(["a", "b", "c", "d"], "POST", []), "Catch All 1");
      expect(router.lookup(["a", "c"], "GET", []), "Catch All 2");
    });


    // Get registered route
    test('Get registered route', () {
      var router = OpenRouter<String>();
      router.addRoute(["a", "b"], "GET", "Hello");
      router.addRoute(["a", "b", "c"], "GET", "World");
      router.addRoute(["a", "b", ":id"], "GET", "Wildcard");
      router.addRoute(["a", "b", ":id"], "ALL", "ALL Wildcard");
      router.addRoute(["a"], "CATCHALL", "Catch All");
      expect(router.getRegisteredRoute(["a", "b"], "GET"), "Hello");
      expect(router.getRegisteredRoute(["a", "b", "c"], "GET"), "World");
      expect(router.getRegisteredRoute(["a", "b", "d"], "GET"), "Wildcard");
      expect(router.getRegisteredRoute(["a", "b", "d"], "ALL"), "ALL Wildcard");
      expect(router.getRegisteredRoute(["a"], "CATCHALL"), "Catch All");

      expect(router.getRegisteredRoute(["a", "c"], "GET"), null);
      expect(router.getRegisteredRoute(["a", "b", "d"], "POST"), null);
      expect(router.getRegisteredRoute(["a", "b", "d", "e"], "GET"), null);
    });
  });
}
