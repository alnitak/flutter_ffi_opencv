import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:ffi_opencv/openCV_imageProvider.dart';
import 'package:ffi_opencv/imgproc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool canBuild;
  bool imageProvider;
  int blurSize;
  int dilateSize;
  Blur _blur;
  Dilate _dilate;

  @override
  void initState() {
    super.initState();
    canBuild = false;
    imageProvider = false;
    blurSize = 1;
    dilateSize = 9;

    _blur = Blur();
    _dilate = Dilate();
    _init();
  }

  _init() async{

    // when using ImgProc.computeSync(), we must use Blur.preloadImage() before
    await _blur.preloadUriImage('assets/solar-system.jpg');

    setState(() {
      canBuild = true;
    });


//    Timer.periodic(Duration(milliseconds: 100), (t) {
//      setState(() {
//        blurSize = Random().nextInt(25) * 2 + 1;
//        _blur.blurSize = blurSize;
//        Uint8List bytes = _blur.computeSync().bytes;
//        if (bytes != null)
//          _image = Image.memory(bytes);
//      });
//    });
  }

  Widget _computeFilters() {
    _blur.kernelSize = blurSize;
    _dilate.kernelSize = dilateSize;
    Uint8List bytes;

    bytes = _blur.computeSync().bytes;

    // feed dilate with the output of blur
    _dilate.preloadBytesImage(bytes);
    bytes = _dilate.computeSync().bytes;

    if (bytes != null)
      return Image.memory(bytes);

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    if (!canBuild)
      return Container();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              RaisedButton(
                child: Text(imageProvider ? 'Using Image Provider' : 'Using Sync' ),
                onPressed: () {
                  imageProvider = !imageProvider;
                  print("*********** imageProvider: $imageProvider");
                  if (!imageProvider)
                    _computeFilters();
                  setState(() {});
                },
              ),

              Text('dilate size: ${dilateSize}x$dilateSize'),
              Slider(
                  value: dilateSize.toDouble(),
                  min: 1,
                  max: 35,
                  onChanged: (value) {},
                  onChangeEnd: (value) {
                    dilateSize = value.floor();
                    setState(() {});
                  }
              ),


              Text('blur size: ${blurSize}x$blurSize'),
              Slider(
                  value: blurSize.toDouble(),
                  min: 1,
                  max: 51,
                  onChanged: (value) {},
                  onChangeEnd: (value) {
                    blurSize = value.floor();
                    setState(() {});
                  }
              ),


              // using OpenCVImageProvider
              if (imageProvider)
                Container(
                  child: Image(
                      image: OpenCVImageProvider(
                        'assets/solar-system.jpg',
                        [
                          Dilate(kernelSize: dilateSize),
                          Blur(kernelSize: blurSize),
                        ]
                  )),
                ),

              // using Blur.computeSync()
              if (!imageProvider)
                Container(
                  color: Colors.yellow,
                  height: 200,
                  child: _computeFilters(),
                ),



            ],
          ),
        ),
      ),
    );
  }
}
