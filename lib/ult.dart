class ULT {
  final double data;

  ULT({this.data});

  factory ULT.fromJson(Map<dynamic, dynamic> json) {
    double parser(dynamic source) {
      try {
        return double.parse(source.toString());
      } on FormatException {
        return -1;
      }
    }

    return ULT(data: parser(json['Data']));
  }
}
