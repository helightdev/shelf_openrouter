/// A trie node that can hold a value of type [T].
class Node<T> {

  /// Nodes with a fixed path segment which are children of this node.
  final Map<String, Node<T>> children = {};

  /// Http verb map for this node.
  final Map<String, T> verbs = {};

  /// Returns the paths the verb has been registered with.
  final Map<String, List<String>> pathMapping = {};

  /// The wildcard node for this node.
  Node<T>? variable;

  /// The catch all node for this node.
  T? catchAll;

  /// The all matcher for this node.
  T? allMatcher;

  /// A trie node that can hold a value of type [T].
  Node(this.allMatcher);

  /// Gets or creates a child node for the given path segment.
  /// If [variable] is true, a variable node is created
  /// If [constant] is provided, a node with the constant path segment is created
  /// At least one of [variable] or [constant] must be provided.
  Node<T> getOrCreate({
    bool variable = false,
    String? constant,
  }) {
    if (variable) {
      this.variable ??= Node<T>(null);
      return this.variable!;
    }
    return children.putIfAbsent(constant!, () => Node<T>(null));
  }
}

/// Represents a registered value in the [OpenRouter] trie router.
class RouterEntry<T> {
  /// The value for this entry.
  T value;
  /// The HTTP verb for this entry.
  String verb;
  /// The path segments for this entry.
  List<String> pathSegments;
  RouterEntry(this.value, this.verb, this.pathSegments);

  @override
  String toString() {
    return "$verb ${pathSegments.join("/")} => $value";
  }
}

/// A simple and extensible trie-like router for handling HTTP requests.
class OpenRouter<T> {

  final Node<T> _root = Node<T>(null);

  /// Returns all registered routes.
  List<RouterEntry<T>> get routes {
    return _findRoutesRecursive(_root);
  }

  List<RouterEntry<T>> _findRoutesRecursive(Node<T> node) {
    final entries = <RouterEntry<T>>[];
    for (var entry in node.verbs.entries) {
      entries.add(RouterEntry(entry.value, entry.key, node.pathMapping[entry.key]!));
    }
    if (node.allMatcher != null) {
      entries.add(RouterEntry<T>(node.allMatcher!, "ALL", node.pathMapping["ALL"]!));
    }
    if (node.catchAll != null) {
      entries.add(RouterEntry<T>(node.catchAll!, "CATCHALL", []));
    }
    for (var entry in node.children.entries) {
      entries.addAll(_findRoutesRecursive(entry.value));
    }
    if (node.variable != null) {
      entries.addAll(_findRoutesRecursive(node.variable!));
    }
    return entries;
  }


  /// Looks up a route in the trie router and
  /// returns the [T] value for the route if found, otherwise null.
  /// Path variables are stored to [paramBuffer].
  /// More details on entry precedence can be found in [addRoute].
  T? lookup(List<String> segments, String verb, List<String> paramBuffer) {
    var node = _root;
    var catchAll = node.catchAll;
    for (var segment in segments) {
      final currentCatchall = node.catchAll;
      if (currentCatchall != null) {
        catchAll = currentCatchall;
      }

      final directMatch = node.children[segment];
      if (directMatch != null) {
        node = directMatch;
        continue;
      }

      final wildcardMatch = node.variable;
      if (wildcardMatch != null) {
        node = wildcardMatch;
        paramBuffer.add(segment);
        continue;
      }

      return catchAll;
    }
    var matchingVerb = node.verbs[verb];
    if (matchingVerb != null) {
      return matchingVerb;
    }

    matchingVerb = node.allMatcher;
    if (matchingVerb != null) {
      return matchingVerb;
    }

    return catchAll;
  }

  /// Adds a route to the trie router.
  /// If the verb is "ALL", the route is registered for all HTTP verbs.
  /// If the verb is "CATCHALL", the route is registered for all paths and verbs
  /// starting at the given path.
  /// Wildcards are supported in the form of `:variable`.
  ///
  /// {@template openrouter.pathvariables}
  /// ### Path Variables
  /// Path variables are supported in the form of `:variable`.
  /// For example, the path `/api/v1/user/:id` will match `/api/v1/user/123`.
  /// {@endtemplate}
  ///
  /// {@template openrouter.precedence}
  /// ### Precedence
  /// The **path lookup** precedence is as follows:
  /// 1. Exact match for a path segment
  /// 2. Wildcard match for a path segment
  /// 3. Nearest catch all match
  ///
  /// The **verb lookup** precedence is as follows:
  /// 1. Exact match for the verb
  /// 2. All matcher
  /// 3. (Catch all matcher)
  /// {@endtemplate}
  void addRoute(List<String> segments, String verb, T value) {
    var node = _root;
    for (var segment in segments) {
      if (segment.startsWith(":")) {
        node = node.getOrCreate(variable: true);
      } else {
        node = node.getOrCreate(constant: segment);
      }
    }

    if (verb == "ALL") {
      node.allMatcher = value;
    } else if (verb == "CATCHALL") {
      node.catchAll = value;
    } else {
      node.verbs[verb] = value;
    }

    node.pathMapping[verb] = segments;
  }

  /// Returns the registered route for the given path segments and verb.
  /// Takes the same parameters as [addRoute] and is not meant for request routing.
  T? getRegisteredRoute(List<String> segments, String verb) {
    var node = _root;
    for (var segment in segments) {
      final directMatch = node.children[segment];
      if (directMatch != null) {
        node = directMatch;
        continue;
      }

      final wildcardMatch = node.variable;
      if (wildcardMatch != null) {
        node = wildcardMatch;
        continue;
      }

      return null;
    }
    if (verb == "ALL") {
      return node.allMatcher;
    } else if (verb == "CATCHALL") {
      return node.catchAll;
    }

    var matchingVerb = node.verbs[verb];
    if (matchingVerb != null) {
      return matchingVerb;
    }

    return null;
  }
}