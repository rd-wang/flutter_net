class NetError {
  static Map<String, String> _error;
  static Map<String, Function> _errorFunction;

  static init(Map<String, String> errorMsg, Map<String, Function> errorHandle) {
    _error = errorMsg;
    _errorFunction = errorHandle;
  }

  static String error(String errorCode) {
    return _error[errorCode];
  }

  static errorFunction(String errorCode) async {
    return await _errorFunction[errorCode]();
  }
}
