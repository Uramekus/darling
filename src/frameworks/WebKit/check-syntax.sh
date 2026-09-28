#!/usr/bin/env bash
# Syntax-checks the guest WebKit surface off-target.
#
# Scope, stated honestly: this proves the files parse as Objective-C and that
# every selector, ivar and function they use is spelled consistently. It does NOT
# prove they link against Darling, because the Foundation/AppKit headers here are
# hand-written stubs covering only the surface these files touch. A change to
# the real SDK could still surface something this cannot see.
#
# It has earned its keep repeatedly: it caught ivars referenced with an
# underscore they were never declared with, a mangled function name, four missing
# system includes, a dead ternary, and a misplaced method.
set -eu
cd "$(dirname "$0")"
for f in src/WKWebView.m src/dwb-siblings.m; do
	clang -fsyntax-only -x objective-c -fblocks -fno-objc-arc -fobjc-nonfragile-abi \
	      -I stubs -I ../src -I . "$f"
	echo "src/$f: syntax OK"
done
# Syntax alone does not cover the performSelector: path between these files.
