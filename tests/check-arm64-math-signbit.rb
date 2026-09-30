# Compile the actual ARM math-header helper for Darwin ARM64 in C and C++.
# This is an ABI/header regression test, not a whole-SDK or runtime test.
require 'tmpdir'
require 'open3'

root = File.realpath(ARGV.fetch(0, File.expand_path('..', __dir__)))
header = 'src/libm/include/architecture/arm/math.h'
helper = File.readlines(File.join(root, header)).find do |line|
  line.match?(/static.*\b__inline_signbit\s*\(.*\{/) 
end
abort "missing long-double helper in #{header}" unless helper

Dir.mktmpdir('arm64-math-signbit-') do |dir|
  { 'c' => 'clang', 'cc' => 'clang++' }.each do |extension, compiler|
    File.write("#{dir}/probe.#{extension}", <<~C)
      _Static_assert(sizeof(long double) == 8, "Darwin ARM64 ABI");
      #{helper}
      #ifdef __cplusplus
      extern "C" {
      #endif
      int negative(void) { return __inline_signbit(-1.0L); }
      int positive(void) { return __inline_signbit(1.0L); }
      int negative_zero(void) { return __inline_signbit(-0.0L); }
      #ifdef __cplusplus
      }
      #endif
    C
    ir, status = Open3.capture2e(compiler, '-target', 'arm64-apple-darwin20',
                                 '-O2', '-S', '-emit-llvm', "#{dir}/probe.#{extension}", '-o', '-')
    abort ir unless status.success?
    expected = { 'negative' => '1', 'positive' => '0', 'negative_zero' => '1' }
    actual = expected.each_with_object({}) do |(name, _), values|
      function = ir[/define[^\n]*@#{name}\(.*?^}/m]
      values[name] = function && function[/ret i32 (\S+)/, 1]
    end
    abort "#{extension}: #{actual.inspect}" unless actual == expected
  end
end
puts 'PASS: ARM64 Darwin long-double signbit is correct in C and C++'
