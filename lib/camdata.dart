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

    String photoid = json.keys.toList()[0];
    print("photoid: $photoid");
    var firstphoto = json[photoid];
    print("photodata: ${firstphoto}");
    Map<dynamic, dynamic> json1 = firstphoto;

    print("photodata1:${json1['data']}");
    return CamData(data: parser(json1['data']));
  }
}
