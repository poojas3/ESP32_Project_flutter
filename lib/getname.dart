class CAM {
  final String data;

  CAM({this.data});

  factory CAM.fromJson(Map<dynamic, dynamic> json) {
    String parser(dynamic source) {
      try {
        return source.toString();
      } on FormatException {
        return "";
      }
    }

    return CAM(data: parser(json['Data']));
  }
}
