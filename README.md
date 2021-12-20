# roobo_net

提供网络访问，网络状态监听，编码转换的基本功能

## Getting Started

# use

1. 初始化 网络库初始化

```text
    /// hostName 域名
    /// authorization 登录签名
    /// isOpenProxy 是否开启代理, 主要用于debug包给测试抓包用
    /// proxyData Map 代理的ip和端口 指定key
    ///             const String PROXY_IP = "debug_proxy_ip";
    ///             const String PROXY_PORT = "debug_proxy_port";
                      { 
                        PROXY_IP: '182.2.2.2',
                        PROXY_PORT: '8833',
                      }
    /// isLog 是否输出log
    /// errorMsg Map<String, String> 错误码集 错误码和提示文案
                                    static Map<String, String> _error = {
                                        '-400': '服务内部错误，内部调用错误',
                                        '-401': '请重新登陆',
                                        '-406': '您没有使用权限，\n请联系机构管理员',
                                        '-422': '参数或者header头必要信息错误',
                                        '-429': '验证码请求次数过多，\n请1小时后重试',
                                        '-451': '验证码已失效\n请重新获取',
                                        '-500': '服务内部错误',
                                        '-100': '网络不给力，请检查网络设置或稍后重试',
                                    };
    /// errorHandle Map<String, Function> 错误码处理集 错误码和响应操作
                                    static Map<String, Function> _errorFunction = {
                                        '-401': showLoginDialog,
                                        '-406': clearAuth,
                                        '-100': showMessage,
                                        '-100866': proxyClean,
                                    };


    Net.init(hostName, authorization, isOpenProxy, proxyData, isLog, errorMsg: errorMsg, errorHandle:errorHandle);
```           

2.网络监听初始化

```text

await NetState.init(listener);

/// listener如下 

static _updateConnectionState(ConnectivityResult result) async {
  NetConnectResult _connectResult;
  switch (result) {
    case ConnectivityResult.wifi:
      _connectResult = NetConnectResult.wifi;
      break;
    case ConnectivityResult.mobile:
      _connectResult = NetConnectResult.mobile;
      break;
    case ConnectivityResult.none:
      _connectResult = NetConnectResult.none;
      ToastUtil.showToast("网络不给力，请检查网络设置或稍后重试", type: ToastType.Info);
      break;
    default:
      _connectResult = NetConnectResult.unknown;
      break;
  }
  NetState.getInstance.netResult = _connectResult;
}
```

3. 调用请求

```text
   /// data: {"id": 12, "name": "xx"},
    /// options: Options(method: "GET"),
    /// T data : ResponseType  ResultData
    /// cancelToken
    /// onSendProgress
    /// onReceiveProgress
    await Net.request(_PATH_USER_UPLOAD_AVATAR, options: Options(contentType: "multipart/form-data"),data: postData, cancelToken: cancelToken);
```

4. 下载

```text
 await Net.download(url, savePath, onReceiveProgress: progressCallback, cancelToken: cancelToken)；
```

5.response

```text
// 结果封装
class ResultData {
  var data;
  var headers;
  dynamic model;
  bool isSuccess;
  String msg;
  int code;

  ResultData(this.data, this.isSuccess, this.code, {this.headers, this.msg});

  @override
  String toString() {
    return ' code:$code\n msg:$msg\n data:$data\n';
  }

```

# other

## NetDataHelper

### // md5

```text
    static string2MD5(String data) {
      var content = Utf8Encoder().convert(data);
      var digest = md5.convert(content);
      return hex.encode(digest.bytes);
    }   
```

### // Base64加密

```text
static String base64ECode(String data) {
    var content = utf8.encode(data);
    var digest = base64Encode(content);
    return digest;
}

```

### // Base64解密

```text
   static String base64DCode(String data) {
        List<int> bytes = base64Decode(data);
        String result = utf8.decode(bytes);
        return result;
    }
   ```

