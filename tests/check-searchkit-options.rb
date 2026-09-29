require 'tmpdir'
require 'open3'
require 'fileutils'
root=File.realpath(ARGV.fetch(0))
Dir.mktmpdir('searchkit-options-') do |dir|
  FileUtils.mkdir_p("#{dir}/CoreFoundation")
  # Isolate the declaration check from unrelated SDK integration conflicts.
  File.write("#{dir}/CoreFoundation/CoreFoundation.h", "typedef unsigned int UInt32;\n")
  File.write("#{dir}/probe.c", <<~C)
    #include "#{root}/src/frameworks/CoreServices/include/SearchKit/SKSearch.h"
    #ifdef __cplusplus
    static_assert(sizeof(SKSearchOptions)==4, "32-bit flags");
    #else
    _Static_assert(sizeof(SKSearchOptions)==4, "32-bit flags");
    #endif
    SKSearchOptions options(void) {
      SKSearchOptions flags=kSKSearchOptionNoRelevanceScores | kSKSearchOptionSpaceMeansOR;
      flags |= kSKSearchOptionFindSimilar;
      return flags;
    }
  C
  %w[arm64-apple-darwin20 x86_64-apple-darwin20].each do |target|
    [['c','gnu11'],['c++','c++17']].each do |language,standard|
      out,status=Open3.capture2e('clang','-target',target,'-x',language,"-std=#{standard}","-I#{dir}",'-fsyntax-only',"#{dir}/probe.c")
      abort out unless status.success?
      puts "PASS #{target} #{language}: options width and combined flags"
    end
  end
end
