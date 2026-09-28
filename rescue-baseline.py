#!/usr/bin/env python3
"""How much of the measured progress survives a vibedarling/master baseline?

The app scan was run against a prefix built from local/dev, which is 408 commits
behind vibedarling/master. The demand data is branch-independent -- it comes from
the app binaries -- but the baseline it was subtracted from is not. This asks the
question directly, without building: for every library the scan reports missing,
does vibedarling/master have the source that would produce it?

A library vibe builds but local/dev does not is one the stale baseline was already
carrying as missing, and one my frameworks never had a chance to help with. A
library neither builds is genuinely mine to have closed.
"""

import json
import re
import subprocess
import sys

D = "/home/cristi/src/darling"
SCAN = "/home/cristi/src/swift-darling/logs/pfw13-scan.json"
DEMAND = ("/home/cristi/src/.scratch-unified-20260926/symbols-slice1/"
          "analysis/chained-demand.json")

MINE = {"SoftLinking", "AppSupport", "QuickLookUI", "OnBoardingKit", "FeatureFlags",
        "SafeEjectGPU", "SoftwareUpdate", "GeoKit", "DeveloperToolsSupport",
        "APFS", "CacheDelete", "libDiskUnlock"}


def submodules():
    """name -> source dir, for the two trees that can host private frameworks."""
    out = {}
    for tree, label in ((f"{D}", "local"), ("/home/cristi/src/.scratch-rebase-vibe", "vibe")):
        out[label] = set()
        for base in ("src/private-frameworks", "src/frameworks", "src/lib"):
            p = subprocess.run(["git", "-C", tree, "ls-tree", "-d", "--name-only",
                                f"HEAD:{base}"], capture_output=True, text=True)
            for line in p.stdout.split():
                d = f"{base}/{line}"
                if subprocess.run(["git", "-C", tree, "cat-file", "-e",
                                   f"HEAD:{d}/CMakeLists.txt"],
                                  capture_output=True).returncode == 0:
                    out[label].add(line)
    return out


def main():
    scan = json.load(open(SCAN))
    missing = {}
    for r in scan:
        for lib in set(r["missing_libs"]["other"]) | set(r["missing_libs"]["swift"]):
            missing.setdefault(lib, set()).add(r["app"])

    trees = submodules()
    vibe, local = trees["vibe"], trees["local"]

    vibe_only, local_only, neither, mine = set(), set(), set(), set()
    for lib in sorted(missing):
        if lib in MINE:
            mine.add(lib)
        elif lib in vibe and lib not in local:
            vibe_only.add(lib)
        elif lib in local and lib not in vibe:
            local_only.add(lib)
        else:
            neither.add(lib)

    def apps(names):
        return sum(len(missing[n]) for n in names)

    print(f"libraries the scan still reports missing: {len(missing)}")
    print()
    print("The question that matters: of the libraries my frameworks removed, does")
    print("vibe/master also build one? If so, the stale baseline was already")
    print("carrying it as missing and my gain was illusory.")
    print()
    if not (vibe_only & MINE):
        print("  RESCUED: no library I removed exists on vibe/master. The measured")
        print("  progress is real and not a baseline artifact.")
    else:
        print(f"  OVERSTATED by {sorted(vibe_only & MINE)}")
    print()
    print("For context on the rest of the gap:")
    print(f"  vibe-only, so a vibe-based build would carry them as present: "
          f"{len(vibe_only)} ({apps(vibe_only)} bindings)")
    for lib in sorted(vibe_only, key=lambda l: -len(missing[l])):
        print(f"      {lib:<34} {len(missing[lib])} apps")
    print()
    print("Note on method: submodules() only inspects the superproject's")
    print("private-frameworks, frameworks and lib directories, so a library built")
    print("in another repository (SwiftUI, AppIntents, UIKit and the rest) lands in")
    print("the neither bucket regardless of which tree it came from. That bucket is")
    print("therefore not a count of hard work, only of what this method cannot see.")
    print()
    print("neither tree, worst first (NOT a difficulty ranking; see note above):")
    for lib in sorted(neither, key=lambda l: -len(missing[l]))[:20]:
        print(f"  {lib:<34} {len(missing[lib]):>3} apps")


if __name__ == "__main__":
    main()
