import 'dart:io';
import 'package:image/image.dart' as img;

Future<File> cropToReceipt(String path) async {
  final bytes = await File(path).readAsBytes();
  img.Image? image = img.decodeImage(bytes);

  if (image == null) return File(path);

  int cropWidth = (image.width * 0.9).toInt();
  int cropHeight = (image.height * 0.75).toInt();

  int offsetX = (image.width - cropWidth) ~/ 2;
  int offsetY = (image.height - cropHeight) ~/ 2;

  img.Image cropped = img.copyCrop(
    image,
    x: offsetX,
    y: offsetY,
    width: cropWidth,
    height: cropHeight,
  );

  final newPath = path.replaceAll(RegExp(r'\.\w+$'), '_crop.jpg');
  return File(newPath)..writeAsBytesSync(img.encodeJpg(cropped));
}