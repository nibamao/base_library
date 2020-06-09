import 'package:baselibrary/constans/constants.dart';

class BaseEntity<T> {
  String respCode;
  String message;
  bool ok;
  dynamic dataStr;
  List< dynamic> listDataStr;

  BaseEntity(this.respCode, this.message, this.ok);

  BaseEntity.fromJson(Map<String, dynamic> json) {
    respCode = json[Constants.code];
    message = json[Constants.message];
    ok = json[Constants.ok];
    if (json.containsKey(Constants.data)) {
      if (json[Constants.data] is List) {
        listDataStr = json[Constants.data];
      } else {
        dataStr = json[Constants.data];
      }
    }
  }


}
