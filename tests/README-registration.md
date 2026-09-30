# Explicit bundle registration

`launchservicesd --register BUNDLE` registers a bundle outside the monitored
directories without starting the daemon loop. Exit status is 0 for committed
registration (including an unchanged bundle), 1 for registration failure, and
2 for invalid command-line usage. It uses CFBundle parsing/package metadata,
not a separate plist parser. It does not implement LSRegisterURL or document
Apple-event delivery.

The transaction coordinator test runs the actual production method with
controlled dependencies on a Linux host with GNUstep:

```sh
ruby tests/launchservices-registration-transaction.rb GNUSTEP_ROOT
```

It covers an unavailable DB, failed begin/setup/UTI/document/URL/commit stages,
exception cleanup, successful processing, and unchanged-bundle success.

The integration fixture includes the actual LSBundle implementation and daemon
entry point (renaming main), and uses real Foundation, CFBundle, FMDB and SQLite.
It must run in a **disposable guest prefix**: it creates fixture apps in /tmp
and modifies /private/var/db/launchservices.db. Do not run against a personal DB.

For an existing ARM64 stage with /work/source and /work/build Ninja recipes:

```sh
ruby tests/build-registration-staged.rb STAGE_BUILD LOCAL_SOURCE
```

Run the printed binary inside a fresh Darling prefix containing the installed
frameworks and launchservicesd-schema.sql resource. Success requires:

```text
PASS registration, PkgInfo metadata, unchanged success, SQLite rollback and retry
```

The guest test checks PkgInfo-derived APPL/creator values, three document-type
forms, exported UTI metadata and URL schemes. SQLite triggers inject an insert
failure separately in each of the eleven registration tables; every table's
row count must remain unchanged, CLI status must be 1, and retry after removing
the trigger must succeed. CLI success and usage statuses are also checked.

Validated on staged ARM64, including both complete changed source files as
objects and a linked fixture using the daemon's own build recipes. This is not
a clean parent build or an x86_64 runtime test. The host failure tests use
controlled dependencies; the guest test does not inject disk-full/commit errors
or exercise FSEvents, XPC, daemon concurrency, handler lookup or app launching.
Existing checksum/caching and malformed-plist policies are not redesigned.
