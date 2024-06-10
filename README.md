# shelf_openrouter
A fast and extensible router for the shelf ecosystem.

## Features

- Better performance than shelf_router using a trie-like routing algorithm.
- Similar api to shelf_router with some additional features.
- Path parameters using the `:param` syntax.
- Non-root catchall routes for a more flexible routing.
- Registrations can be retrieved at runtime.

## Getting Started
Add the project to your `pubspec.yaml` file.
```yaml
dependencies:
  shelf_openrouter: ^0.0.1
```

## Usage
```dart
Future<void> main() async {
  var app = ShelfOpenRouter();
  router.get("/api/v1/hello", (Request request) {
    return Response.ok("Hello");
  });
  router.get("/api/v1/hello/:name", (Request request, String name) {
    return Response.ok("Hello $name");
  });

  await shelf_io.serve(router.call, 'localhost', 8080);
}
```

## Base Router
If you want to integrate the base router into a framework that requires
routing, you can use the `OpenRouter` class. The object stored using the router
can be changed and has no restrictions on the type of object stored.

All route registrations can be retrieved after they have been added which makes
it easier to generate openapi documentation. 

(If you don't use shelf, just copy the `router.dart` file and use it as you see fit.
This project uses the MIT-0 license, so you can do whatever you want with it.)