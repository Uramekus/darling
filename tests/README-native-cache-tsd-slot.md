The loader advertises `darling_tsd_slot_offset=<hex>` in the Mach-O apple
vector. On ARM64 it identifies a dedicated pointer slot in native ELF TLS,
relative to TPIDR_EL0. The main executable's ELF TLS offset is stable across
native pthreads. Other architectures advertise UINTPTR_MAX.

A cooperating libsystem_kernel publishes Darwin TSD into that slot. A
cooperating dyld can translate cached Darwin thread-pointer reads into native
TP plus slot loads, avoiding a SIGILL for every read. Older consumers ignore
the metadata; this change does not expand the unversioned elf_calls table.
The slot must not be reused for native TLS-restoration or compatibility state.

Run `ruby tests/native-cache-tsd-slot.rb .` on ARM64 Linux. It compiles the
production slot declaration/getter and checks 40000 reads/writes across four
native threads. This is a loader-side native test; it does not establish
end-to-end guest support without the kernel and dyld consumers.
