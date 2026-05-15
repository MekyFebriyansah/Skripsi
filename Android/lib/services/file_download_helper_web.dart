import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> downloadFileBytes({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final base64Data = base64Encode(bytes);
  final anchor = html.AnchorElement(
    href: 'data:$mimeType;base64,$base64Data',
  )
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  return fileName;
}
