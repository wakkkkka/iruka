import 'package:flutter/material.dart';
import 'path_image_stub.dart'
    if (dart.library.io) 'path_image_io.dart'
    if (dart.library.html) 'path_image_web.dart';

Widget buildPathImage({
  required String path,
  double? height,
  double? width,
  BoxFit? fit,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return buildPathImageImpl(
    path: path,
    height: height,
    width: width,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
