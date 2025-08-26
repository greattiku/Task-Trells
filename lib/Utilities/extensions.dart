import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension AppIntSizer on int {
  int get h => (MediaQuery.of(Get.context!).size.height * (this / 844)).toInt();
  int get w => (MediaQuery.of(Get.context!).size.width * (this / 390)).toInt();
}

extension AppDoubleSizer on double {
  double get h => MediaQuery.of(Get.context!).size.height * (this / 844);
  double get w => MediaQuery.of(Get.context!).size.width * (this / 390);
}