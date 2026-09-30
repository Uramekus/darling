require 'tmpdir'
require 'open3'
root=File.expand_path('..',__dir__)
source=File.read("#{root}/src/startup/mldr/stack.c")
declaration=source[/char elfcalls_size\[[^;]+;/] or abort 'size buffer missing'
writer=source[/\tsnprintf\(elfcalls_size,.*?\tmemcpy\(elfcalls_size_user, elfcalls_size, sizeof\(elfcalls_size\)\);/m] or abort 'writer missing'
abort 'stack reservation missing' unless source.lines.grep(/sp -=/).any?{|l| l.include?('sizeof(elfcalls_size)')}
abort 'vector terminator missing' unless source.include?('applep_contents[4] = NULL;')
abort 'vector entry missing' unless source.include?('applep_contents[3] = elfcalls_size_user;')
Dir.mktmpdir('elfcalls-size-') do |dir|
  code=<<~C
    #include <assert.h>
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include "#{root}/src/startup/mldr/elfcalls/elfcalls.h"
    int main(void) {
      struct elf_calls _elfcalls;
      #{declaration}
      char storage[256]; memset(storage,0x55,sizeof(storage));
      char *elfcalls_user=storage+128, *elfcalls_size_user;
      #{writer}
      assert(strncmp(elfcalls_size_user,"elf_calls_size=",15)==0);
      assert(strtoul(elfcalls_size_user+15,NULL,16)==sizeof(_elfcalls));
      assert(elfcalls_size_user[-1]==0x55 && elfcalls_user[0]==0x55);
      int n=snprintf(elfcalls_size,sizeof(elfcalls_size),"elf_calls_size=%zx",(size_t)-1);
      assert(n>0 && (size_t)n<sizeof(elfcalls_size));
      puts("PASS: actual size writer, maximum formatting capacity and adjacent sentinels");
    }
  C
  File.write("#{dir}/probe.c",code)
  out,status=Open3.capture2e('clang','-fsanitize=address,undefined',"#{dir}/probe.c",'-o',"#{dir}/probe")
  abort out unless status.success?
  out,status=Open3.capture2e("#{dir}/probe")
  puts out
  abort 'metadata test failed' unless status.success?
end
