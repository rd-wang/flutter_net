import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class NetDataHelper {
  // md5
  static string2MD5(String data) {
    var content = Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  // Base64加密
  static String base64ECode(String data) {
    var content = utf8.encode(data);
    var digest = base64Encode(content);
    return digest;
  }

  // Base64解密
  static String base64DCode(String data) {
    List<int> bytes = base64Decode(data);
    String result = utf8.decode(bytes);
    return result;
  }
}