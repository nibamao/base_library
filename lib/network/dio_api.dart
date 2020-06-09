import 'dart:convert';

import 'package:baselibrary/base/base_entity.dart';
import 'package:baselibrary/constans/constants.dart';
import 'package:baselibrary/utils/log_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'error_handle.dart';
import 'intercept.dart';

/// 网络请求封装库
class DioApi {
  static final DioApi _singleton = DioApi._internal();

  static DioApi get instance => DioApi();

  factory DioApi() {
    return _singleton;
  }

  static Dio _dio;

  Dio getDio() {
    return _dio;
  }

  DioApi._internal() {
    var options = BaseOptions(
      connectTimeout: 15000,
      receiveTimeout: 15000,
      responseType: ResponseType.plain,
      validateStatus: (status) {
        // 不使用http状态码判断状态，使用AdapterInterceptor来处理（适用于标准REST风格）
        return true;
      },
      baseUrl: Constants.baseUrl,
//      contentType: ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8'),
    );
    _dio = Dio(options);

    /// Fiddler抓包代理配置 
//    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
//        (HttpClient client) {https://www.jianshu.com/p/d831b1f7c45b
//      client.findProxy = (uri) {
//        //proxy all request to localhost:8888
//        return "PROXY 10.41.0.132:8888";
//      };
//      client.badCertificateCallback =
//          (X509Certificate cert, String host, int port) => true;
//    };
    /// 统一添加身份验证请求头
    _dio.interceptors.add(AuthInterceptor());

    /// 打印Log(生产模式去除)
    if (!Constants.inProduction) {
      _dio.interceptors.add(LoggingInterceptor());
    }

    /// 适配数据(根据自己的数据结构，可自行选择添加)
    _dio.interceptors.add(AdapterInterceptor());
  }

  // 数据返回格式统一，统一处理异常
  Future<BaseEntity<T>> _request<T>(String method, String url,
      {dynamic data,
      Map<String, dynamic> queryParameters,
      CancelToken cancelToken,
      Options options}) async {
    var response = await _dio.request(url,
        data: data,
        queryParameters: queryParameters,
        options: _checkOptions(method, options),
        cancelToken: cancelToken);
    try {
      /// 集成测试无法使用 isolate
      Map<String, dynamic> _map = Constants.isTest
          ? parseData(response.data.toString())
          : await compute(parseData, response.data.toString());
      return BaseEntity.fromJson(_map);
    } catch (e) {
      print(e);
      return BaseEntity(ExceptionHandle.parse_error as String, "数据解析错误", false);
    }
  }

  Options _checkOptions(method, options) {
    if (options == null) {
      options = new Options();
    }
    options.method = method;
    return options;
  }

  Future requestNetwork<T>(Method method, String url,
      {Function onStart,
      Function(dynamic t) onSuccess,
      Function(List<dynamic> list) onSuccessList,
      Function(int code, String msg) onError,
      Function onDone,
      dynamic params,
      Map<String, dynamic> queryParameters,
      CancelToken cancelToken,
      Options options,
      bool isList: false}) async {
    String m = _getRequestMethod(method);
    onStart();
    return await _request<T>(m, url,
            data: params,
            queryParameters: queryParameters,
            options: options,
            cancelToken: cancelToken)
        .then((BaseEntity<T> result) {
      if (result.respCode == "0") {
        if (isList) {
          if (onSuccessList != null) {
            onSuccessList(result.listDataStr);
            onDone();
          }
        } else {
          if (onSuccess != null) {
            onSuccess(result.dataStr);
            onDone();
          }
        }
      } else {
        _onError(result.respCode as int , result.message, onError);
        onDone();
      }
    }, onError: (e, _) {
      _cancelLogPrint(e, url);
      NetError error = ExceptionHandle.handleException(e);
      _onError(error.code, error.msg, onError);
      onDone();
    });
  }

  /// 统一处理(onSuccess返回T对象，onSuccessList返回List<T>)
  asyncRequestNetwork<T>(Method method, String url,
      {Function onStart,
      Function(dynamic t) onSuccess,
      Function(List<dynamic> list) onSuccessList,
      Function(int code, String msg) onError,
      Function onDone,
      dynamic params,
      Map<String, dynamic> queryParameters,
      CancelToken cancelToken,
      Options options,
      bool isList: false}) {
    String m = _getRequestMethod(method);
    onStart();
    Stream.fromFuture(_request<T>(m, url,
            data: params,
            queryParameters: queryParameters,
            options: options,
            cancelToken: cancelToken))
        .asBroadcastStream()
        .listen((result) {
      if (result.respCode == "0") {
        if (isList) {
          if (onSuccessList != null) {
            onSuccessList(result.listDataStr);
          }
        } else {
          if (onSuccess != null) {
            onSuccess(result.dataStr);
          }
        }
      } else {
        _onError(result.respCode as int, result.message, onError);
      }
    }, onError: (e) {
      _cancelLogPrint(e, url);
      NetError error = ExceptionHandle.handleException(e);
      _onError(error.code, error.msg, onError);
    }, onDone: onDone);
  }

  _cancelLogPrint(dynamic e, String url) {
    if (e is DioError && CancelToken.isCancel(e)) {
      Log.e("取消请求接口： $url");
    }
  }

  _onError(int code, String msg, Function(int code, String mag) onError) {
    if (code == null) {
      code = ExceptionHandle.unknown_error;
      msg = "未知异常";
    }
    Log.e("接口请求异常： code: $code, mag: $msg");
    if (onError != null) {
      onError(code, msg);
    }
  }

  String _getRequestMethod(Method method) {
    String m;
    switch (method) {
      case Method.get:
        m = "GET";
        break;
      case Method.post:
        m = "POST";
        break;
      case Method.put:
        m = "PUT";
        break;
      case Method.patch:
        m = "PATCH";
        break;
      case Method.delete:
        m = "DELETE";
        break;
      case Method.head:
        m = "HEAD";
        break;
    }
    return m;
  }
}

Map<String, dynamic> parseData(String data) {
  return json.decode(data);
}

enum Method { get, post, put, patch, delete, head }
