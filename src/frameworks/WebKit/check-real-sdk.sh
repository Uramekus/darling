#!/bin/sh
# Compile the guest's Objective-C against the REAL Darling SDK headers.
#
# The stub-based check (guest/check-syntax.sh) only proves the file parses against
# headers I wrote to match it. That is a closed loop: if my stub is wrong in the
# same way my code is wrong, it agrees with me. This uses the SDK headers
# darling's own build uses, so a real API mismatch shows up.
#
# Read-only. Nothing is written into the darling tree and no build is run; this is
# a syntax-only compile of one probe file.
#
# The flags are lifted from the WebKit target's own entry in build.ninja, because
# the SDK headers are only self-consistent under that exact combination - a
# hand-rolled -I list produces errors in Foundation itself, which says nothing
# about this code. The control below proves the flags are right by compiling an
# upstream WebKit file with them first.
set -eu

DARLING=${DARLING:-/home/cristi/src/darling}
SDK="$DARLING/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
GEN="$DARLING/build/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include"
NINJA="$DARLING/build/build.ninja"

if [ ! -f "$DARLING/framework-include/WebKit/WKWebView.h" ]; then
	echo "darling SDK headers not found under $DARLING" >&2
	exit 77
fi

# Read straight out of the build so it cannot drift from what darling does. Both
# the FLAGS and the DEFINES lines are needed: without -DDARLING -D__APPLE__ and
# friends, Foundation's own headers select the wrong branch and fail with errors
# that have nothing to do with the code under test.
if [ -f "$NINJA" ]; then
	ENTRY=$(grep -m1 -A6 'build src/frameworks/WebKit/CMakeFiles/WebKit.dir/src/DOMElement.m.o' "$NINJA" || true)
	BUILD_FLAGS=$(printf '%s\n' "$ENTRY" | sed -n 's/^  FLAGS = //p' | head -1)
	BUILD_DEFINES=$(printf '%s\n' "$ENTRY" | sed -n 's/^  DEFINES = //p' | head -1)
	BUILD_INCLUDES=$(printf '%s\n' "$ENTRY" | sed -n 's/^  INCLUDES = //p' | head -1)
fi

if [ -z "${BUILD_FLAGS:-}" ]; then
	echo "could not read the WebKit compile flags out of $NINJA" >&2
	echo "Run this from a configured darling checkout, or set them by hand." >&2
	exit 77
fi

# -fsyntax-only and -c -o /dev/null replace the real -o; -fblocks is what lets
# the guest's completion block compile at all, which the stub check supplies
# separately and this does not.
FLAGS="-fsyntax-only -fblocks $BUILD_DEFINES $BUILD_FLAGS $BUILD_INCLUDES"

# The real guest sources. Not the probe - the actual files that would land.
SRC_DIR=$(cd "$(dirname "$0")" && pwd)
status=0
for f in "$SRC_DIR/src/WKWebView.m" "$SRC_DIR/src/dwb-siblings.m"; do
	name=$(basename "$f")
	if [ ! -f "$f" ]; then
		echo "  MISSING  $name"
		status=1
		continue
	fi

	# One invocation, status captured, and any diagnostic at all is a failure.
	#
	# Two earlier versions of this loop reported "ok" unconditionally on the error
	# paths, so a missing header and a genuine type error both looked like a pass.
	# A check that cannot fail is worse than no check, because it is believed.
	#
	# The transport headers sit beside the guest sources, so src/ is on the
	# include path. Pointing at the wrong directory once meant every compile
	# stopped at "dwb_client.h file not found" while the loop reported "ok" -
	# a check that passes because it never reached the code.
	out=$(clang $FLAGS -I"$SRC_DIR/include" -I"$SRC_DIR/src" -c "$f" -o /dev/null 2>&1) && rc=0 || rc=$?

	errs=$(printf '%s\n' "$out" | grep -c 'error:' || true)

	# -Wobjc-method-access is a failure here, not a warning.
	#
	# A selector the SDK does not declare is reported as a warning ("return type
	# defaults to id") and the compile still succeeds, so the loop above passed a
	# file that sends two selectors Darling does not have - the very bug the
	# check exists to find. Renaming pixelsHigh: back to bitsHigh: still
	# reported "both sources compile" until this was added. A check that passes
	# known-bad input is not a check.
	meth=$(printf '%s\n' "$out" | grep -cE "warning: instance method .* not found|warning: 'NSObject' may not respond" || true)
	if [ "$rc" -eq 0 ] && [ "$errs" -eq 0 ] && [ "$meth" -eq 0 ]; then
		warns=$(printf '%s\n' "$out" | grep -c 'warning:' || true)
		echo "  ok       $name (${warns} warnings)"
	else
		echo "  FAILED   $name (clang exit ${rc}, ${errs} error(s), ${meth} unknown method(s))"
		printf '%s\n' "$out" | grep -E 'error:' | head -6 | sed 's/^/             /'
		status=1
	fi
done

if [ "$status" -eq 0 ]; then
	echo "both guest sources compile against the real Darling SDK"
fi
exit "$status"
