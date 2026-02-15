import 'dart:io';
import 'package:flutter/material.dart';

Widget buildPathImageImpl({
  required String path,
  double? height,
  double? width,
  BoxFit? fit,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return Image.file(
    File(path),
    height: height,
    width: width,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
