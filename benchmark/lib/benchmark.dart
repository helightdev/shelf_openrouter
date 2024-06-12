List<(String verb, String path, String value)> routes = [
// Get
  ('GET', '/api/v1/health', 'health'),
  ('GET', '/api/v1/health/:id', 'health-id'),
  ('GET', '/api/v1/health/:id/:name', 'health-id-name'),
  ('GET', '/api/v1/health/:id/:name/:age', 'health-id-name-age'),
// Post
  ('POST', '/api/v1/health', 'health-post'),
  ('POST', '/api/v1/health/:id', 'health-id-post'),
  ('POST', '/api/v1/health/:id/:name', 'health-id-name-post'),
  ('POST', '/api/v1/health/:id/:name/:age', 'health-id-name-age-post'),
// all
  ('ALL', '/api/v1/health', 'health-all'),
  ('ALL', '/api/v1/health/:id', 'health-id-all'),
  ('ALL', '/api/v1/health/:id/:name', 'health-id-name-all'),
  ('ALL', '/api/v1/health/:id/:name/:age', 'health-id-name-age-all'),
];

List<(String method, String path, String expected)> tests = [
  ('GET', '/api/v1/health', 'health'),
  ('GET', '/api/v1/health/1', 'health-id'),
  ('GET', '/api/v1/health/1/john', 'health-id-name'),
  ('GET', '/api/v1/health/1/john/20', 'health-id-name-age'),
  ('POST', '/api/v1/health', 'health-post'),
  ('POST', '/api/v1/health/1', 'health-id-post'),
  ('POST', '/api/v1/health/1/john', 'health-id-name-post'),
  ('POST', '/api/v1/health/1/john/20', 'health-id-name-age-post'),
  //('PUT', '/api/v1/health', 'health-all'),
  //('PUT', '/api/v1/health/1', 'health-id-all'),
  //('PUT', '/api/v1/health/1/john', 'health-id-name-all'),
  //('PUT', '/api/v1/health/1/john/20', 'health-id-name-age-all'),
];

abstract class RouterBenchmark {

  void prepare();
  void run();

}