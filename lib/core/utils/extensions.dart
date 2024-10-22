import 'package:flutter/material.dart';

extension SizeExt on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
}

extension SpacesExt on int {
  Widget get toHorizontalSpace => SizedBox(width: toDouble());
  Widget get toVerticalSpace => SizedBox(height: toDouble());
}