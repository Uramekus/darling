# Focused ABI check: compile the actual long-double helper extracted from each
# header. This is not a whole-SDK header or runtime test.
require 'tmpdir'
require 'open3'
root = File.realpath(ARGV.fetch(0))
target = ENV.fetch('PROBE_TARGET', 'arm64-apple-darwin20')
long_double_size = target.start_with?('arm64') ? 8 : 16
headers = ARGV.drop(1)
headers = %w[src/libm/include/architecture/arm/math.h] if headers.empty?
failed = false
Dir.mktmpdir('arm-math-signbit-') do |dir|
  headers.each do |header|
    helper = File.readlines(File.join(root, header)).find { |line| line.match?(/static.*\b__inline_signbit\s*\(.*\{/) }
    abort "Missing long-double helper in #{header}" unless helper
    File.write("#{dir}/probe.c", <<~C)
      _Static_assert(sizeof(long double) == #{long_double_size}, "Darwin long double ABI");
      #{helper}
      int negative(void) { return __inline_signbit(-1.0L); }
      int positive(void) { return __inline_signbit(1.0L); }
      int negative_zero(void) { return __inline_signbit(-0.0L); }
    C
    ir, status = Open3.capture2e('clang', '-target', target, '-O2', '-S', '-emit-llvm', "#{dir}/probe.c", '-o', '-')
    abort ir unless status.success?
    results = {'negative' => 1, 'positive' => 0, 'negative_zero' => 1}.map do |name, expected|
      body = ir[/define[^\n]*@#{name}\(.*?^}/m]
      actual = body && body[/ret i32 (\S+)/, 1]
      [name, actual, expected]
    end
    ok = results.all? { |_, actual, expected| actual == expected.to_s }
    failed ||= !ok
    puts "#{ok ? 'PASS' : 'FAIL'} #{header}: #{results.map { |name, actual, expected| "#{name}=#{actual} (expected #{expected})" }.join(', ')}"
  end
end
exit(failed ? 1 : 0)
