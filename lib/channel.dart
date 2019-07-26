import 'package:flutter/services.dart';

const platform = const MethodChannel('sample.flutter.dev/sample');

void invoke() async {
  print(await platform.invokeMethod('method'));
}