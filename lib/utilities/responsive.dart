import 'package:flutter/material.dart';

class R {
  static double w(BuildContext c) => MediaQuery.of(c).size.width;
  static double h(BuildContext c) => MediaQuery.of(c).size.height;

  static double wp(BuildContext c, double percent) =>
      w(c) * percent / 100;

  static double hp(BuildContext c, double percent) =>
      h(c) * percent / 100;

  static double sp(BuildContext c, double size) =>
      size * (w(c) / 375); // base width

  static bool isTablet(BuildContext c) => w(c) > 600;
}