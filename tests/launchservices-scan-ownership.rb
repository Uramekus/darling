#!/usr/bin/env ruby
# Actual scanner/init/dealloc with GNUstep and a controlled CF bundle producer.
require 'tmpdir'
root = ARGV.shift or abort 'usage: ruby tests/launchservices-scan-ownership.rb GNUSTEP_ROOT [LSBundle.m]'
source = File.read(ARGV.shift || File.expand_path('../src/frameworks/CoreServices/src/LaunchServices/launchservicesd/LSBundle.m', __dir__))
scan = source[/\+\(void\)scanForBundles:\(NSString\*\)dir\n\{.*?\n\}/m] or abort 'scanner missing'
init = source[/-\(id\) initWithBundle:.*?\n\}/m] or abort 'initializer missing'
dealloc = source[/-\(void\)dealloc.*?\n\}/m] or abort 'dealloc missing'
Dir.mktmpdir('ls-scan-') do |dir|
  code = <<~'OBJC'
    #import <Foundation/Foundation.h>
    #include <assert.h>
    typedef id CFBundleRef;
    typedef id CFURLRef;
    static int made, destroyed, processed, mode;
    @interface FixtureBundle : NSObject { @public BOOL identified; }
    @end
    @implementation FixtureBundle
    -(void)dealloc { ++destroyed; [super dealloc]; }
    @end
    static id CFRetain(id object) { return [object retain]; }
    static void CFRelease(id object) { assert(object); [object release]; }
    static id CFBundleGetIdentifier(FixtureBundle* bundle) { return bundle->identified ? @"test.fixture" : nil; }
    static id CFBundleCreateBundlesFromDirectory(void* allocator, CFURLRef url, id type) {
      assert(allocator == NULL && type == nil && [url isFileURL]);
      if (mode == 3) return nil;
      NSMutableArray* result = [[NSMutableArray alloc] init];
      int count = mode == 2 ? 0 : 3;
      for (int i = 0; i < count; ++i) {
        FixtureBundle* bundle = [[FixtureBundle alloc] init];
        ++made;
        bundle->identified = mode == 0 && i != 1;
        [result addObject:bundle];
        // API special contract: transfer the create retain for every bundle
        // in addition to the retaining array, just like CFBundle.c does.
      }
      return result;
    }
    @interface LSBundle : NSObject { CFBundleRef _bundle; }
    -(id)initWithBundle:(CFBundleRef)bundle;
    -(void)process;
    +(void)scanForBundles:(NSString*)dir;
    @end
    @implementation LSBundle
    -(void)process { assert(((FixtureBundle*)_bundle)->identified); ++processed; }
  OBJC
  code += [init, dealloc, scan, '@end'].join("\n") + "\n"
  code += <<~'OBJC'
    int main(void) {
      @autoreleasepool {
        for (mode = 0; mode < 4; ++mode) {
          made = destroyed = processed = 0;
          [LSBundle scanForBundles:@"/fixture"];
          assert(made == (mode < 2 ? 3 : 0));
          assert(processed == (mode == 0 ? 2 : 0));
          assert(destroyed == made);
        }
      }
      puts("PASS: mixed, all-skipped, empty and nil bundle arrays balance ownership");
    }
  OBJC
  File.write("#{dir}/probe.m", code)
  gcc_include = IO.popen(['gcc', '-print-file-name=include'], &:read).strip
  system('clang', '-fobjc-runtime=gcc', '-fconstant-string-class=NSConstantString', "-I#{root}/usr/include/GNUstep", "-I#{gcc_include}", "#{dir}/probe.m", "-L#{root}/usr/lib", "-Wl,-rpath,#{root}/usr/lib", '-lgnustep-base', '-lobjc', '-o', "#{dir}/probe", exception: true)
  system("#{dir}/probe", exception: true)
end
