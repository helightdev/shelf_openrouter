extension StringExtension on String {

  List<String> get segments {
    var str = this;
    if (str.startsWith('/')) {
      str = str.substring(1);
    }
    if (str.endsWith('/')) {
      str = str.substring(0, str.length - 1);
    }
    return str.split('/');
  }
}

class SegmentUtils {

  static List<String> getVariableSegments(String path) => path.segments
        .where((element) => element.startsWith(':'))
        .map((element) => element.substring(1))
        .toList();

}