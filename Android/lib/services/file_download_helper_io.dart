import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> downloadFileBytes({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final dir = await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}
