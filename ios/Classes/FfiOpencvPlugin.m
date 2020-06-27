#import "FfiOpencvPlugin.h"
#if __has_include(<ffi_opencv/ffi_opencv-Swift.h>)
#import <ffi_opencv/ffi_opencv-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ffi_opencv-Swift.h"
#endif

@implementation FfiOpencvPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFfiOpencvPlugin registerWithRegistrar:registrar];
}
@end
