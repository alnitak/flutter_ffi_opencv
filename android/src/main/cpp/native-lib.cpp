#include <android/log.h>

#include "opencv2/core.hpp"
#include "opencv2/core/mat.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/imgcodecs.hpp"

#define ATTRIBUTES extern "C" __attribute__((visibility("default"))) __attribute__((used))

#define DEBUG_NATIVE true

using namespace cv;

/**  @brief
 *
 * @param img pointer to a encoded image bytes
 * @param imgLengthBytes reference pointer to return image length in bytes
 *
 * Return the Mat() of the decoded image
 */
ATTRIBUTES void *opencv_decodeImage(
        unsigned char *img,
        int32_t *imgLengthBytes) {

    cv::Mat *src = new Mat();
    int32_t a = *imgLengthBytes;
    std::vector<unsigned char> m;

    while ( a>=0 )
    {
        m.push_back(*(img++));
        a--;
    }

    *src = cv::imdecode(m, cv::IMREAD_UNCHANGED);
    if (src->data == nullptr)
        return nullptr;

    if (DEBUG_NATIVE)
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE", "opencv_decodeImage() ---  len before:%d  len after:%d  width:%d  height:%d",
            *imgLengthBytes, src->step[0] * src->rows,
            src->cols, src->rows);

    *imgLengthBytes = src->step[0] * src->rows;
    return src;
}

/**  @brief Returns a pointer to the encoded image bytes. Remember to free() the returned Pointer<> in Dart!
 *
 * @param img pointer to a Mat image object
 * @param imgLengthBytes reference pointer to return image length in bytes
 * @param blurSize squared kernel size
 *
 */
ATTRIBUTES unsigned char *opencv_blur(
        void *imgMat,
        int32_t *imgLengthBytes,
        int32_t kernelSize) {

    cv::Mat *src = (Mat*)imgMat;

    if (src == nullptr || src->data == nullptr)
        return nullptr;

    if (DEBUG_NATIVE)
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE", "opencv_blur() ---  len:%d  width:%d   height:%d",
                            src->step[0] * src->rows, src->cols, src->rows);

    Mat dst =  cv::Mat();

    blur(*src, dst, Size(kernelSize, kernelSize), Point(-1, -1));

    std::vector<uchar> buf(1); // imencode() will resize it
//    Encoding with b       mp : 20-40ms
//    Encoding with jpg : 50-70 ms
//    Encoding with png: 200-250ms
    cv::imencode(".bmp", dst, buf);
    if (DEBUG_NATIVE)
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE", "opencv_blur()  resulting image  length:%d   %d x %d", buf.size(), dst.cols, dst.rows);

    *imgLengthBytes = buf.size();

    // the return value may be freed by GC before dart receive it??
    // Sometimes in Dart, ImgProc.computeSync() receives all zeros while here buf.data() is filled correctly
    // Returning a new allocated memory.
    // Note: remember to free() the Pointer<> in Dart!
    unsigned char *ret = (unsigned char *)malloc(buf.size());
    memcpy(ret, buf.data(), buf.size());
    return ret;
//    return buf.data();
}

/**  @brief Returns a pointer to the encoded image bytes. Remember to free() the returned Pointer<> in Dart!
 *
 * @param img pointer to a Mat image object
 * @param imgLengthBytes reference pointer to return image length in bytes
 * @param blurSize squared kernel size
 *
 */
ATTRIBUTES unsigned char *opencv_dilate(
        void *imgMat,
        int32_t *imgLengthBytes,
        int32_t kernelSize) {

    cv::Mat *src = (Mat*)imgMat;


    if (src == nullptr || src->data == nullptr)
        return nullptr;

    if (DEBUG_NATIVE)
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE", "opencv_dilate() ---  len:%d  width:%d   height:%d",
                            src->step[0] * src->rows, src->cols, src->rows);

    Mat dst =  cv::Mat();


    dilate(
            *src,
            dst,
            getStructuringElement(MORPH_ELLIPSE,
                                  Size((2*kernelSize) + 1, (2*kernelSize)+1)),
            Point(kernelSize, kernelSize)
    );


    std::vector<uchar> buf(1); // imencode() will resize it
//    Encoding with b       mp : 20-40ms
//    Encoding with jpg : 50-70 ms
//    Encoding with png: 200-250ms
    cv::imencode(".bmp", dst, buf);
    if (DEBUG_NATIVE)
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE", "opencv_dilate()  resulting image  length:%d   %d x %d", buf.size(), dst.cols, dst.rows);

    *imgLengthBytes = buf.size();

    // the return value may be freed by GC before dart receive it??
    // Sometimes in Dart, ImgProc.computeSync() receives all zeros while here buf.data() is filled correctly
    // Returning a new allocated memory.
    // Note: remember to free() the Pointer<> in Dart!
    unsigned char *ret = (unsigned char *)malloc(buf.size());
    memcpy(ret, buf.data(), buf.size());
    return ret;
//    return buf.data();
}
