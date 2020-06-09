import 'package:baselibrary/constans/constants.dart';
import 'package:fish_redux/fish_redux.dart';

/// 输出Log工具类
class Log {
  static init() {}

  static d(String msg, {tag: 'X-LOG'}) {
    if (!Constants.inProduction) {
      println(msg);
    }
  }

  static e(String msg, {tag: 'X-LOG'}) {
    if (!Constants.inProduction) {
      println(msg);
    }
  }

  static json(String msg, {tag: 'X-LOG'}) {
    println(msg);
  }
}
