class Constants {
  /// debug开关，上线需要关闭
  /// App运行在Release环境时，inProduction为true；当App运行在Debug和Profile环境时，inProduction为false
  static const bool inProduction =
      const bool.fromEnvironment("dart.vm.product");

  static bool isTest = true;

  static const String data = 'data';
  static const String message = 'message';
  static const String code = 'respCode';
  static const String ok = 'ok';

  static const String phone = 'phone';
  static const String accessToken = 'token';

  static const baseUrl = 'http://xz.yuhuadt.com/jeecg/';
}
