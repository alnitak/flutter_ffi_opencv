# ffi_opencv

Plugin to use OpenCV with dart:ffi

## Getting Started

Download OpenCV sources for Android from
[here](https://opencv.org/releases/),
then edit **android/CMakeLists.txt** to point **OPENCV_DIR** variable to the unzipped OpenCV path.

By subclassing ImgProc to add a new image filter, you should averride *compute()* or *computeSync()* or both.

**compute()** is used by *OpenCVImageProvider* asynchronously. That means that the image is read and decompressed every time it is needed by *OpenCVImageProvider*.

**computeSync()** calls the C filter with an already loaded image cv::Mat. Use *preloadUriImage()* or *preloadBytesImage()* to store the iamge before calling *computeSync()*.

By now there are only 2 image proc filters: *blur* and *dilate*.

#
***using OpenCVImageProvider***
```
Image(
      image: OpenCVImageProvider(
        'assets/solar-system.jpg', // only assets images for now
        [ // list of filters
          Dilate(kernelSize: 9),
          Blur(kernelSize: 15),
        ]
  )),
)
```
***using computeSync()***  
define your subclassed ImgProc classes:

```
  Blur _blur;
  Dilate _dilate;

  @override
  void initState() {
    super.initState();
    _blur = Blur();
    _dilate = Dilate();
    _init();
  }  
```
the *_init()* method is used to preload asynchronously the image into the first to process ImgProc class:
```
  _init() async{
    // when using ImgProc.computeSync(), we must use Blur.preloadImage() before
    await _blur.preloadUriImage('assets/solar-system.jpg');

    setState(() {
      canBuild = true;
    });
  }
```
when done, the *build()* can be called.


The preloaded image is processed by *Blur* and the resulting image bytes are then passed to *Dilate* to be processed.
```
Widget _computeFilters() {
    Uint8List bytes = _blur.computeSync().bytes;

    if (bytes != null) {
      // feed dilate with the output of blur
      _dilate.preloadBytesImage(bytes);
      bytes = _dilate.computeSync().bytes;
    }

    if (bytes != null)
      return Image.memory(bytes);

    return Container(child: Text('Image filter error'));
  }
```

#### issues
Sometimes the 2nd *computeSync()* returns wrong image bytes.  
On my Asus Zenfone there is some kind of about freeing pointer.