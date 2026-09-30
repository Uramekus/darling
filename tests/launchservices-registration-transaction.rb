#!/usr/bin/env ruby
# Execute the actual transaction coordinator with controlled stage failures.
require 'tmpdir'
root = ARGV.fetch(0)
source = File.read(File.expand_path('../src/frameworks/CoreServices/src/LaunchServices/launchservicesd/LSBundle.m', __dir__))
process = source[/-\(BOOL\)process\n\{.*?\n\}/m] or abort 'BOOL process missing'
Dir.mktmpdir('ls-registration-') do |dir|
  code = <<~'OBJC'
    #import <Foundation/Foundation.h>
    #include <assert.h>
    typedef id CFBundleRef;
    static NSString *kUTExportedTypeDeclarationsKey = @"UTExportedTypeDeclarations";
    static id CFBundleGetInfoDictionary(id bundle) { return bundle; }
    static int failStage, began, rolledBack, committed, processed, visits;
    static BOOL unchanged;
    @interface Database : NSObject
    -(BOOL)beginTransaction;
    -(BOOL)rollback;
    -(BOOL)commit;
    @end
    @implementation Database
    -(BOOL)beginTransaction { ++began; return failStage != 1; }
    -(BOOL)rollback { ++rolledBack; return YES; }
    -(BOOL)commit { ++committed; return failStage != 6; }
    @end
    static Database *g_database;
    @interface LSBundle : NSObject { @public CFBundleRef _bundle; int _bundleId; }
    -(BOOL)process;
    -(BOOL)setupBundleID:(BOOL*)needed;
    -(BOOL)processUTIs:(id)utis;
    -(BOOL)processFileAssociations;
    -(BOOL)processURLTypes;
    @end
    @implementation LSBundle
    -(BOOL)setupBundleID:(BOOL*)needed {
      ++visits; _bundleId = 42; *needed = !unchanged;
      return failStage != 2;
    }
    -(BOOL)processUTIs:(id)utis {
      assert(utis == nil); ++processed;
      if (failStage == 7) [NSException raise:@"Fixture" format:@"rollback on exception"];
      return failStage != 3;
    }
    -(BOOL)processFileAssociations { ++processed; return failStage != 4; }
    -(BOOL)processURLTypes { ++processed; return failStage != 5; }
  OBJC
  code += process + "\n@end\n"
  code += <<~'OBJC'
    int main(void) {
      @autoreleasepool {
        LSBundle *bundle = [LSBundle new];
        bundle->_bundle = [NSDictionary dictionary];
        assert(![bundle process]); // unavailable DB cannot report success
        assert(began == 0);
        g_database = [Database new];
        for (failStage = 0; failStage <= 7; ++failStage) {
          began = rolledBack = committed = processed = visits = 0;
          BOOL result = NO, threw = NO;
          @try { result = [bundle process]; }
          @catch (NSException *error) { assert([[error name] isEqual:@"Fixture"]); threw = YES; }
          assert(result == (failStage == 0));
          assert(threw == (failStage == 7));
          assert(began == 1);
          assert(rolledBack == (failStage >= 2));
          assert(committed == (failStage == 0 || failStage == 6));
          assert(visits == (failStage != 1));
          int expected = failStage == 1 || failStage == 2 ? 0 :
            failStage == 3 || failStage == 7 ? 1 : failStage == 4 ? 2 : 3;
          assert(processed == expected);
          if (failStage >= 2) assert(bundle->_bundleId == 0);
        }
        failStage = 0; unchanged = YES;
        began = rolledBack = committed = processed = 0;
        assert([bundle process]);
        assert(began == 1 && committed == 1 && !rolledBack && !processed);
        assert(bundle->_bundleId == 42);
        [bundle release]; [g_database release];
      }
      puts("PASS: unavailable DB, begin/setup/write/commit failures, exception rollback, success and unchanged success");
    }
  OBJC
  File.write("#{dir}/probe.m", code)
  gcc_include = IO.popen(['gcc', '-print-file-name=include'], &:read).strip
  system('clang', '-fobjc-runtime=gcc', '-fobjc-exceptions', '-fexceptions',
    '-fconstant-string-class=NSConstantString', "-I#{root}/usr/include/GNUstep", "-I#{gcc_include}",
    "#{dir}/probe.m", "-L#{root}/usr/lib", "-Wl,-rpath,#{root}/usr/lib", '-lgnustep-base', '-lobjc',
    '-o', "#{dir}/probe", exception: true)
  system("#{dir}/probe", exception: true)
end
