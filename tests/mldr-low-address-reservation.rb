# Execute the loader's allocation block with real Linux mappings and an injected
# high-address result. No Mach-O loading or cache initialization is simulated.
require 'tmpdir'
require 'open3'
source=File.read(File.join(File.realpath(ARGV.fetch(0, File.expand_path('..', __dir__))), 'src/startup/mldr/loader.c'))
block=source[/\t\tvoid\* mmap_hint = .*?(?=\t\t\/\/ unmap it so)/m] or abort 'allocation block missing'
Dir.mktmpdir('mldr-low-address-') do |dir|
  File.write("#{dir}/test.cpp", <<~CPP)
    #include <sys/mman.h>
    #include <sys/wait.h>
    #include <unistd.h>
    #include <stdint.h>
    #include <stdio.h>
    #include <string.h>
    #include <errno.h>
    #include <assert.h>
    #define MAP_EXTRA 0
    static bool injectHigh;
    static const uintptr_t fakeHigh=0x800000100000ULL;
    static void* test_mmap(void *a,size_t n,int p,int f,int fd,off_t o) {
      if (injectHigh) { injectHigh=false; return (void*)fakeHigh; }
      return mmap(a,n,p,f,fd,o);
    }
    static int test_munmap(void *a,size_t n) {
      return (uintptr_t)a==fakeHigh ? 0 : munmap(a,n);
    }
    static void test_exit(int status) { throw status; }
    static uintptr_t allocate(size_t mmapSize) {
      uintptr_t base=0,slide=0;
    #define mmap test_mmap
    #define munmap test_munmap
    #define exit test_exit
    #{block}
    #undef mmap
    #undef munmap
    #undef exit
      return slide;
    }
    int main() {
      size_t page=sysconf(_SC_PAGESIZE);
      for (int mode=0;mode<3;++mode) {
        pid_t child=fork(); assert(child>=0);
        if (!child) {
          char *old=(char*)mmap((void*)0x200000000ULL,page,PROT_READ|PROT_WRITE,
              MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED_NOREPLACE,-1,0);
          assert(old==(void*)0x200000000ULL); old[0]=41;
          char *occupied=nullptr;
          if (mode==2) {
            occupied=(char*)mmap((void*)0x1000000000ULL,page,PROT_READ|PROT_WRITE,
                MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED_NOREPLACE,-1,0);
            assert(occupied==(void*)0x1000000000ULL); occupied[0]=42;
          }
          injectHigh=mode!=0;
          bool rejected=false;
          try {
            uintptr_t result=allocate(page);
            assert(mode!=2);
            assert(result>=0x1000000000ULL && result<0x800000000000ULL);
            assert(munmap((void*)result,page)==0);
          } catch (int status) { assert(status==1); rejected=true; }
          assert(rejected==(mode==2));
          assert(old[0]==41);
          if (occupied) assert(occupied[0]==42);
          _exit(0);
        }
        int status; assert(waitpid(child,&status,0)==child);
        assert(WIFEXITED(status) && WEXITSTATUS(status)==0);
      }
      puts("PASS low placement, high-address retry, occupied retry rejection and sentinel preservation");
    }
  CPP
  out,status=Open3.capture2e('clang++','-std=c++11','-fsanitize=undefined',"#{dir}/test.cpp",'-o',"#{dir}/test")
  abort out unless status.success?
  out,status=Open3.capture2e("#{dir}/test")
  puts out
  abort 'loader allocation regression failed' unless status.success?
end
