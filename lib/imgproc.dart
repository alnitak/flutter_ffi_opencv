import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Base class for the compute() method of ImgProc.
class CVImage {
  String uri;
  Uint8List bytes;
  Pointer<Void> decodedMatImgPointer;
  Pointer<Int32> imgByteLength;

  CVImage() {
    bytes = Uint8List(0);
    imgByteLength = allocate<Int32>();
  }
}

/// Base class for image filters
abstract class ImgProc {
  DynamicLibrary nativeLib;
  Pointer<Void> Function(Pointer<Uint8> img, Pointer<Int32> imgLengthBytes) decodeImage;
  CVImage preloadedImage;

  ImgProc() {
    nativeLib = Platform.isAndroid
        ? DynamicLibrary.open("libnative-lib.so")
        : DynamicLibrary.process();
    decodeImage = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Uint8>, Pointer<Int32>)>>("opencv_decodeImage")
        .asFunction();
  }

  // Loads the image to store and use it later in the overloaded computeSync()
  Future<bool> preloadUriImage(String uri) async{
    assert(uri != null, 'You must provide an image URI!');

    if (preloadedImage == null)
      preloadedImage = CVImage();

    // get image bytes
    preloadedImage.bytes = await getBytes(uri);
    if ( preloadedImage.bytes == null ||
        preloadedImage.bytes.length < 1024) {
      print("ImgProc error: invalid image");
      preloadedImage.uri = null;
      return false;
    }

    preloadedImage.imgByteLength.value = preloadedImage.bytes.length;
    Pointer<Uint8> imgBytes = intListToArray(preloadedImage.bytes);

    // decode image with OpenCV
    preloadedImage.decodedMatImgPointer = decodeImage(
        imgBytes,
        preloadedImage.imgByteLength
    );

    preloadedImage.uri = uri;
    return true;
  }

  // Loads the image to store and use it later in the overloaded computeSync()
  bool preloadBytesImage(Uint8List bytes) {
    if (preloadedImage == null)
      preloadedImage = CVImage();

    // get image bytes
    preloadedImage.bytes = bytes;
    if ( preloadedImage.bytes == null ||
        preloadedImage.bytes.length < 1024) {
      print("ImgProc error: invalid image");
      preloadedImage.uri = null;
      return false;
    }

    preloadedImage.imgByteLength.value = preloadedImage.bytes.length;
    Pointer<Uint8> imgBytes = intListToArray(preloadedImage.bytes);

    // decode image with OpenCV
    preloadedImage.decodedMatImgPointer = decodeImage(
        imgBytes,
        preloadedImage.imgByteLength
    );

    return true;
  }

  Pointer<Uint8> intListToArray(Uint8List list) {
    final Pointer<Uint8> ptr = allocate<Uint8>(count: list.length);
    for (var i = 0; i < list.length; i++) {
      ptr.elementAt(i).value = list[i];
    }
    return ptr;
  }

  Future<Uint8List> getBytes(String uri) async{
    // TODO manage URIs other then assets
    Uint8List ret = (await rootBundle.load(uri)).buffer.asUint8List();
    return ret;
  }

  /// Override this
  computeSync() {
    assert(preloadedImage == null ||
        preloadedImage.bytes == null ||
        preloadedImage.bytes.length > 1024
    );
  }

  Future<CVImage> compute({String uri, Uint8List bytes}) {
    assert(uri != null || bytes != null);
  }
}



//////////////////////////////////////
/// BLUR
class Blur extends ImgProc {
  Pointer<Uint8> Function(Pointer<Void> img, Pointer<Int32> imgLengthBytes, int kernelSize) blur;
  int kernelSize;

  setKernelSize(int kernelSize) {
    assert(kernelSize < 1, "kernelSize must be greater then 1");
    this.kernelSize = kernelSize;
  }

  Blur({this.kernelSize = 3}) {
    blur = nativeLib
        .lookup<NativeFunction<Pointer<Uint8> Function(Pointer<Void>, Pointer<Int32>, Int32)>>("opencv_blur")
        .asFunction();
  }


  /// preloadedImage should not be empty. Before this, call [preloadUriImage]
  @override
  CVImage computeSync() {
    super.computeSync();
    CVImage ret = CVImage();
    Pointer<Uint8> resultImg = blur(
        preloadedImage.decodedMatImgPointer,
        ret.imgByteLength,
        kernelSize);
    ret.bytes = resultImg.asTypedList(ret.imgByteLength.value);

    free(resultImg);
    return ret;
  }

  @override
  Future<CVImage> compute({String uri, Uint8List bytes}) async{
    CVImage ret = CVImage();

    ret.bytes = bytes==null ? await getBytes(uri) : bytes;
    if (ret.bytes == null)
      return null;
    Pointer<Uint8> imgBytes = intListToArray(ret.bytes);
    ret.imgByteLength.value = ret.bytes.length;
    ret.decodedMatImgPointer = decodeImage(
        imgBytes,
        ret.imgByteLength
    );

    Pointer<Uint8> resultImg = blur(ret.decodedMatImgPointer, ret.imgByteLength, kernelSize);

    ret.bytes = resultImg.asTypedList(ret.imgByteLength.value);

    free(resultImg);
    return ret;
  }
}




//////////////////////////////////////
/// DILATE
class Dilate extends ImgProc {
  Pointer<Uint8> Function(Pointer<Void> img, Pointer<Int32> imgLengthBytes, int kernelSize) dilate;
  int kernelSize;

  setKernelSize(int kernelSize) {
    this.kernelSize = kernelSize;
  }

  Dilate({this.kernelSize = 3}) {
    dilate = nativeLib
        .lookup<NativeFunction<Pointer<Uint8> Function(Pointer<Void>, Pointer<Int32>, Int32)>>("opencv_dilate")
        .asFunction();
  }


  /// preloadedImage should not be empty. Before this, call [preloadUriImage]
  @override
  CVImage computeSync() {
    super.computeSync();
    CVImage ret = CVImage();
    Pointer<Uint8> resultImg = dilate(
        preloadedImage.decodedMatImgPointer,
        ret.imgByteLength,
        kernelSize);
    ret.bytes = resultImg.asTypedList(ret.imgByteLength.value);

    free(resultImg);
    return ret;
  }

  @override
  Future<CVImage> compute({String uri, Uint8List bytes}) async{
    CVImage ret = CVImage();

    ret.bytes = bytes==null ? await getBytes(uri) : bytes;
    if (ret.bytes == null)
      return null;
    Pointer<Uint8> imgBytes = intListToArray(ret.bytes);
    ret.imgByteLength.value = ret.bytes.length;
    ret.decodedMatImgPointer = decodeImage(
        imgBytes,
        ret.imgByteLength
    );

    Pointer<Uint8> resultImg = dilate(ret.decodedMatImgPointer, ret.imgByteLength, kernelSize);

    ret.bytes = resultImg.asTypedList(ret.imgByteLength.value);

    free(resultImg);
    return ret;
  }
}
