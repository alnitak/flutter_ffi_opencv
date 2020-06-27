
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'imgproc.dart';


class OpenCVImageProvider extends ImageProvider<OpenCVImageProvider> {

  String uri;
  List<ImgProc> imgProcList;

  OpenCVImageProvider(
      this.uri,
      this.imgProcList,
      {
        this.scale = 1.0,
      })
      : assert(uri != null),
        assert(imgProcList != null && imgProcList.length > 0);

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;


  Future<Codec> _fetchImage() async {
    CVImage cvImage;
    Uint8List bytes;
    cvImage = await imgProcList.elementAt(0).compute(uri: uri);
    for (int i=1; i<imgProcList.length; i++) {
      if (cvImage.bytes == null)
        continue;
      cvImage = await imgProcList.elementAt(i).compute(bytes: cvImage.bytes);
    }

    if (cvImage.bytes == null) {
      print("OpenCVImageProvider _fetchImage() error: invalid image");
      return null;
    }

    if (cvImage.bytes.length > 0)
      return PaintingBinding.instance.instantiateImageCodec(cvImage.bytes);

    return null;
  }


  @override
  Future<OpenCVImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<OpenCVImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(OpenCVImageProvider key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
        codec: key._fetchImage(),
        scale: key.scale,
        informationCollector: () sync* {
          yield DiagnosticsProperty<ImageProvider>(
            'Image provider: $this \n Image key: $key', this,
            style: DiagnosticsTreeStyle.errorProperty,
          );
        });
  }
}
