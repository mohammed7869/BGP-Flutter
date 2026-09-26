import 'dart:html' as html;
import 'dart:convert';

Future<void> downloadFileImpl(List<int> bytes, String fileName) async {
  final base64 = base64Encode(bytes);
  final anchor = html.AnchorElement(
      href: 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64')
    ..setAttribute('download', fileName)
    ..click();
}
