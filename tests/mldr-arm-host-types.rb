# Usage on Linux/aarch64: ruby tests/mldr-arm-host-types.rb /path/to/xnu
require 'tmpdir'
require 'open3'
root=File.expand_path('..',__dir__)
xnu=File.realpath(ARGV.fetch(0))
abort 'requires a Linux/aarch64 host' unless RUBY_PLATFORM.include?('linux') && RUBY_PLATFORM.include?('aarch64')
Dir.mktmpdir('mldr-arm-types-') do |dir|
  source=<<~C
    #include <sys/types.h>
    #include <stdio.h>
    #include <stdint.h>
    #include <mach/arm/vm_types.h>
    _Static_assert(sizeof(__darwin_natural_t) == sizeof(unsigned int), "Mach natural type");
    _Static_assert(sizeof(mach_vm_address_t) == 8, "Mach address type");
    int main(void) { return 0; }
  C
  File.write("#{dir}/probe.c",source)
  flags=['clang','-fsyntax-only','-D__arm64__=1','-DDARLING',"-I#{xnu}/osfmk","-I#{xnu}/EXTERNAL_HEADERS",'-idirafter',"#{xnu}/bsd"]
  baseline,status=Open3.capture2e(*flags,"#{dir}/probe.c")
  abort 'negative control did not expose host typedef conflicts' if status.success? || !baseline.include?('typedef redefinition')
  output,status=Open3.capture2e(*flags,"-I#{root}/src/startup/mldr/include","#{dir}/probe.c")
  abort output unless status.success?
  puts 'PASS: Linux host types coexist with Mach ARM VM types; unshimmed negative control fails'
end
