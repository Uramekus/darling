# Exercise the production native-loader cache TSD slot across native threads.
require 'tmpdir'
require 'open3'
root=File.realpath(ARGV.fetch(0))
s=File.read("#{root}/src/startup/mldr/elfcalls/threads.c")
helper=s[/static __thread void\* shared_cache_darling_tsd;.*?^\}/m] or abort 'native TLS block missing'
Dir.mktmpdir('mldr-native-tsd-slot-') do |dir|
 File.write("#{dir}/test.c", <<~C)
 #include <stdint.h>
 #include <stddef.h>
 #include <assert.h>
 #include <pthread.h>
 #include <stdio.h>
 #{helper}
 static __thread void* unrelated_native_state;
 static uintptr_t offset;
 static void* worker(void* argument) {
   void* native=__builtin_thread_pointer();
   assert(__darling_arm64_tsd_slot_offset()==offset);
   void** slot=(void**)((uintptr_t)native+offset);
   assert(*slot==NULL);
   for(unsigned i=0;i<10000;++i) {
     *slot=argument;
     unrelated_native_state=native;
     assert(unrelated_native_state==native);
     assert(*slot==argument && __builtin_thread_pointer()==native);
   }
   return NULL;
 }
 int main(void) {
   offset=__darling_arm64_tsd_slot_offset();
   assert(offset>=16 && offset<=32760 && !(offset&7));
   pthread_t threads[4];
   for(uintptr_t i=0;i<4;++i) assert(pthread_create(&threads[i],NULL,worker,(void*)(i+1))==0);
   for(unsigned i=0;i<4;++i) assert(pthread_join(threads[i],NULL)==0);
   puts("PASS dedicated native cache TSD slot: 40000 reads/writes across four threads");
 }
 C
 out,status=Open3.capture2e('cc','-O2','-pthread',"#{dir}/test.c",'-o',"#{dir}/test");abort out unless status.success?
 out,status=Open3.capture2e("#{dir}/test");puts out;abort 'native slot isolation failed' unless status.success?
end
