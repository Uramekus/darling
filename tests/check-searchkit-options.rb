# Compile the actual SearchKit declaration for both supported Darwin targets.
# This is a focused header/type test, not a framework build or runtime test.
require 'tmpdir'
require 'open3'
require 'fileutils'

root = File.realpath(ARGV.fetch(0, File.expand_path('..', __dir__)))
Dir.mktmpdir('searchkit-options-') do |dir|
  FileUtils.mkdir_p("#{dir}/CoreFoundation")
  File.write("#{dir}/CoreFoundation/CoreFoundation.h", "typedef unsigned int UInt32;\n")
  File.write("#{dir}/probe.c", <<~C)
    #include "#{root}/src/frameworks/CoreServices/include/SearchKit/SKSearch.h"
    #ifdef __cplusplus
    static_assert(sizeof(SKSearchOptions) == 4, "32-bit flags");
    #else
    _Static_assert(sizeof(SKSearchOptions) == 4, "32-bit flags");
    #endif
    SKSearchOptions options(void) {
      SKSearchOptions flags = kSKSearchOptionNoRelevanceScores | kSKSearchOptionSpaceMeansOR;
      flags |= kSKSearchOptionFindSimilar;
      return flags;
    }
  C
  %w[arm64-apple-darwin20 x86_64-apple-darwin20].each do |target|
    [['c', 'gnu11'], ['c++', 'c++17']].each do |language, standard|
      output, status = Open3.capture2e('clang', '-target', target, '-x', language,
                                       "-std=#{standard}", "-I#{dir}", '-fsyntax-only', "#{dir}/probe.c")
      abort output unless status.success?
      puts "PASS #{target} #{language}: options width and combined flags"
    end
  end
end
