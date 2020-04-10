#import "BetterassetsPlugin.h"
#if __has_include(<betterassets/betterassets-Swift.h>)
#import <betterassets/betterassets-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "betterassets-Swift.h"
#endif

@implementation BetterassetsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBetterassetsPlugin registerWithRegistrar:registrar];
}
@end
