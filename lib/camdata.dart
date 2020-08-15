class CamData {
  final String data;

  CamData({this.data});

  factory CamData.fromJson(Map<dynamic, dynamic> json) {
    String parser(dynamic source) {
      try {
        return source.toString();
      } on FormatException {
        return '-1';
      }
    }

    return CamData(data: parser(json['Data']));
  }
}
