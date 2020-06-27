cmake_minimum_required(VERSION 3.4.1)

# download OpenCV for Android from here:
# https://opencv.org/releases/
# set here the OpenCV path
set (OPENCV_DIR /home/deimos/Documents/workspace/FLUTTER/libs/OpenCV-android-sdk)


include_directories(${OPENCV_DIR}/sdk/native/jni/include)
add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${OPENCV_DIR}/sdk/native/libs/${ANDROID_ABI}/libopencv_java4.so)



# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.

add_library( # Sets the name of the library.
        native-lib

        # Sets the library as a shared library.
        SHARED

        # Provides a relative path to your source file(s).
        src/main/cpp/native-lib.cpp )

# Searches for a specified prebuilt library and stores the path as a
# variable. Because CMake includes system libraries in the search path by
# default, you only need to specify the name of the public NDK library
# you want to add. CMake verifies that the library exists before
# completing its build.

find_library(
        # Sets the name of the path variable.
        log-lib

        # Specifies the name of the NDK library that
        # you want CMake to locate.
        log )

# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

target_link_libraries( # Specifies the target library.
        native-lib
        -ljnigraphics
        lib_opencv
        # Links the target library to the log library
        # included in the NDK.
        ${log-lib})


# Copy OpenCV library to project
add_custom_command(TARGET native-lib POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        ${OPENCV_DIR}/sdk/native/libs/${ANDROID_ABI}/libopencv_java4.so
        ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/libopencv_java4.so
        )