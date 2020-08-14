import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageProcess extends StatefulWidget {
  static const String id = "image_process";
  @override
  _ImageProcessState createState() => _ImageProcessState();
}

class _ImageProcessState extends State<ImageProcess> {
  final Firestore fb = Firestore.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: FutureBuilder(
        future: getImages(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data.documents.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    contentPadding: EdgeInsets.all(8.0),
                    title: Text(snapshot.data.documents[index].data["name"]),
                    leading: Image.network(
                        snapshot.data.documents[index].data["url"],
                        fit: BoxFit.fill),
                  );
                });
          } else if (snapshot.connectionState == ConnectionState.none) {
            return Text("No data");
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }

  Future<QuerySnapshot> getImages() {
    return fb.collection("images").getDocuments();
  }
}
