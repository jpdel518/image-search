import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PixabayPage extends StatefulWidget {
  @override
  State<PixabayPage> createState() {
    return _PixabayPageState();
  }
}

class _PixabayPageState extends State<PixabayPage> {
  List<PixabayImage> pixabayImages = [];

  /// pixabayからデータを取得.
  Future<void> fetchImages(String query) async {
    final Response res = await Dio().get(
        'https://pixabay.com/api/',
      queryParameters: {
        'key': '29833265-0811fbd309e763a4567f55f52',
        'q': query,
        'image_type': 'photo',
        'per_page': 100
      }
    );
    final List hits = res.data['hits'];
    pixabayImages = hits.map((e) {
      return PixabayImage.fromMap(e);
    }).toList();
    setState(() {});
  }

  /// 画像をダウンロードして共有.
  Future<void> shareImage(String url) async {
    // 1.URLから画像をダウンロード
    Response res = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        )
    );
    // 2.ダウンロードしたデータをファイルに保存(path_providerは一時的に保存する先を取得)
    final Directory dir = await getTemporaryDirectory();
    final File file = await File("${dir.path}/image.png").writeAsBytes(res.data);
    // 3.Shareパッケージを呼び出して共有
    Share.shareFiles([file.path]);
  }

  @override
  void initState() {
    super.initState();
    // 最初に一度だけ呼ばれる
    fetchImages('花');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
          ),
          onFieldSubmitted: (text) {
            fetchImages(text);
          },
        ),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemBuilder: (context, index) {
          PixabayImage pixabayImage = pixabayImages[index];
          return InkWell(
            onTap: () async {
              shareImage(pixabayImage.webformatURL);
            },
            child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    pixabayImage.previewURL,
                    fit: BoxFit.cover,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.thumb_up_alt_outlined),
                          Text('${pixabayImage.likes}'),
                        ],
                      ),
                      color: Colors.white,
                    ),
                  ),
                ]
            ),
          );
        },
        itemCount: pixabayImages.length,
      )
    );
  }
}

class PixabayImage {
  final String webformatURL;
  final String previewURL;
  final int likes;

  // {}は名前付き引数にするためにつける
  PixabayImage({
    required this.webformatURL,
    required this.previewURL,
    required this.likes
  });

  factory PixabayImage.fromMap(Map<String, dynamic> map) {
    return PixabayImage(
        webformatURL: map['webformatURL'],
        previewURL: map['previewURL'],
        likes: map['likes']
    );
  }
}
