import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_openrouter/shelf_openrouter.dart';

void main() async {
  var router = ShelfOpenRouter();
  router.get("/api/v1/hello", (Request request) {
    return Response.ok("Hello");
  });
  router.get("/api/v1/hello/:name", (Request request, String name) {
    return Response.ok("Hello $name");
  });

  await shelf_io.serve(router.call, 'localhost', 8080);
}