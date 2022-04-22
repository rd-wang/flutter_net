library roobo_net;

import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:roobo_net/roobo_net_error.dart';

import 'net_state/net_state.dart';

const String PROXY_IP = "debug_proxy_ip";
const String PROXY_PORT = "debug_proxy_port";

class Net {
  static late Dio _dio;
  static late Dio _downloadDio;
  static bool? isOpenProxy;

  /// hostName 域名
  /// authorization 登录签名
  /// isOpenProxy 是否开启代理, 主要用于debug包给测试抓包用
  /// proxyData Map 代理的ip和端口 指定key
  ///             const String PROXY_IP = "debug_proxy_ip";
  //              const String PROXY_PORT = "debug_proxy_port";
  /// isLog 是否输出log
  /// errorMsg Map<String, String> 错误码集 错误码和提示文案
  /// errorHandle Map<String, Function> 错误码处理集 错误码和响应操作
  static void init(
    String hostName,
    String authorization,
    bool isOpenProxy,
    Map proxyData,
    bool isLog, {
    Map<String, String> errorMsg = const {},
    Map<String, Function> errorHandle = const {},
  }) {
    _downloadDio = new Dio();
    NetError.init(errorMsg, errorHandle);
    Net.isOpenProxy = isOpenProxy;
    _dio = new Dio(BaseOptions(
        baseUrl: hostName, method: "POST", contentType: Headers.jsonContentType, responseType: ResponseType.json, connectTimeout: 5000, receiveTimeout: 3000, sendTimeout: 50000));

    if (isOpenProxy) {
      // More about HttpClient proxy topic please refer to Dart SDK doc.
      (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
        client.findProxy = (uri) {
          //proxy all request to localhost:8888
          StringBuffer stringBuffer = StringBuffer();
          stringBuffer.write("PROXY ");
          stringBuffer.write(proxyData[PROXY_IP]);
          stringBuffer.write(":");
          stringBuffer.write(proxyData[PROXY_PORT]);
          // return "PROXY 172.17.132.214:8888";
          return stringBuffer.toString();
        };
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    _dio.interceptors.add(InterceptorsWrapper(onRequest: (RequestOptions requestOptions, handler) async {
      requestOptions.headers["Authorization"] = authorization;
      return handler.next(requestOptions);
    }, onResponse: (Response response, handler) async {
      // 在返回响应数据之前做一些处理
      // 一般只需要处理200的情况，300、400、500保留错误信息
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 业务是否成功的code
        int? code = response.data["result"];
        if (errorHandle.containsKey(code.toString())) {
          await NetError.errorFunction(code.toString());
        }
        String? msg;
        if (code != 0) {
          msg = NetError.error(code.toString());
          if (msg == null) {
            msg = response.data['msg'];
          }
          print(response.data);
        }
        response.data = ResultData(response.data['data'], code == 0, code, headers: response.headers, msg: msg);
      }
      return handler.next(response);
    }, onError: (DioError e, handler) async {
      if (e.type == DioErrorType.connectTimeout) {
        await NetError.errorFunction('-100');
      } else if (e.type == DioErrorType.cancel) {
        // 主动取消
        print("this request is canceled");
      }

      if (isOpenProxy) {
        if ((e.error is SocketException) || (e.error is ArgumentError)) {
          await NetError.errorFunction('-100866');
          init(hostName, authorization, false, proxyData, isLog,errorMsg: errorMsg,errorHandle: errorHandle);
        }
      }
      // 此时的失败不是业务失败
      return handler.resolve(Response(requestOptions: RequestOptions(path: ''), data: e, statusCode: -1010));
    }));

    // 由于拦截器队列的执行顺序是FIFO，如果把log拦截器添加到了最前面，则后面拦截器对options的更改就不会被打印（但依然会生效）， 所以建议把log拦截添加到队尾。
    _dio.interceptors.add(LogInterceptor(
      request: isLog,
      requestHeader: isLog,
      requestBody: isLog,
      responseHeader: isLog,
      responseBody: isLog,
      error: isLog,
    ));
  }

  /// data: {"id": 12, "name": "xx"},
  /// options: Options(method: "GET"),
  /// T data : ResponseType  ResultData
  static Future<ResultData?> request<T>(String path,
      {data, Map? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    // response.data 为拦截器返回的内容
    if (NetState.getInstance!.netResult == NetConnectResult.unknown || NetState.getInstance!.netResult == NetConnectResult.none) {
      print("no_net");
      String? error = NetError.error('-100');
      return ResultData(error, false, -100, msg: error);
    }
    Response response = await _dio.request<T>(path,
        data: data, queryParameters: queryParameters as Map<String, dynamic>?, options: options, cancelToken: cancelToken, onSendProgress: onSendProgress, onReceiveProgress: onReceiveProgress);
    if (response.statusCode == -1010) {
      return ResultData(response.data, false, response.statusCode, msg: "");
    }
    return response.data;
  }

  static void cancelRequest(CancelToken cancelToken) {
    cancelToken?.cancel(['canceled']);
  }

// 下载文件
  static Future<bool> download<T>(String urlPath, String savePath,
      {ProgressCallback? onReceiveProgress, Map<String, dynamic>? queryParameters, CancelToken? cancelToken, data, Options? options}) async {
    try {
      Response response =
          await _downloadDio.download(urlPath, savePath, onReceiveProgress: onReceiveProgress, options: Options(responseType: ResponseType.json), cancelToken: cancelToken);
      return response.statusCode == 200;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }
}

// 结果封装
class ResultData {
  var data;
  var headers;
  dynamic model;
  bool isSuccess;
  String? msg;
  int? code;

  ResultData(this.data, this.isSuccess, this.code, {this.headers, this.msg});

  @override
  String toString() {
    return ' code:$code\n msg:$msg\n data:$data\n';
  }
}
