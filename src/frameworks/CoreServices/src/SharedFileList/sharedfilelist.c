/*
  This file is part of Darling.

  Copyright (C) 2026 Darling Developers

  Darling is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Darling is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Darling.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <SharedFileList/SharedFileList.h>
#include <CarbonCore/MacErrors.h>

#include <stdlib.h>
#include <string.h>

/*
 * A list is an array of URLs and nothing else. LaunchServices' real list
 * persists items, resolves each to an alias and icon, and hands back a snapshot
 * ordered by use. None of that exists here, and pretending otherwise would mean
 * returning URLs for files that were never added or an item count that drifts
 * from what the caller can actually open -- so the list is exactly the array it
 * was given, and the snapshot is that array copied.
 *
 * What this does buy is the part callers actually need to survive startup: the
 * three entry points a client links against. Blender reached
 * LSSharedFileListCreate from -[NSApplication finishLaunching]'s notification
 * path and died on the missing symbol before it drew anything.
 */

struct OpaqueLSSharedFileList {
	CFMutableArrayRef items;
};

static LSSharedFileListRef _lsCreateWithArray(CFArrayRef inListOrArray) {
	struct OpaqueLSSharedFileList* list = calloc(1, sizeof(struct OpaqueLSSharedFileList));

	if (list == NULL) {
		return NULL;
	}

	if (inListOrArray != NULL) {
		list->items = CFArrayCreateMutableCopy(NULL, 0, inListOrArray);
	}
	else {
		list->items = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	}

	if (list->items == NULL) {
		free(list);
		return NULL;
	}

	return list;
}

/*
 * inListIdentifier and inImagesToHide are accepted and ignored. The identifier
 * names which list is being opened, and there is no store to look it up in; the
 * image array is used by Finder to suppress icons, and there is no icon
 * resolution here. Returning an empty list for an unknown identifier is the
 * honest answer: a caller asking for a list we have never seen gets no items
 * rather than items from some other list.
 */
LSSharedFileListRef LSSharedFileListCreate(CFUUIDRef inListIdentifier, CFArrayRef inListOrArray,
                                           CFArrayRef inImagesToHide) {
	(void)inListIdentifier;
	(void)inImagesToHide;

	return _lsCreateWithArray(inListOrArray);
}

void LSSharedFileListDeallocate(LSSharedFileListRef inList) {
	if (inList == NULL) {
		return;
	}

	if (inList->items != NULL) {
		CFRelease(inList->items);
	}

	free(inList);
}

CFIndex LSSharedFileListGetCount(LSSharedFileListRef inList) {
	if (inList == NULL || inList->items == NULL) {
		return 0;
	}

	return CFArrayGetCount(inList->items);
}

/*
 * outRef is left alone rather than zeroed. It is a Carbon FSRef, 80 bytes whose
 * layout is not declared in this tree, and writing a guessed length into a
 * caller's buffer is worse than leaving it: the caller passes NULL when it does
 * not want one, and the URL is the part it can actually use.
 */
OSStatus LSSharedFileListItemResolve(LSSharedFileListRef inList, CFURLRef inItemURL,
                                    CFURLRef* outResolvedURL, void* outRef, UInt32* outRefSeed) {
	(void)inList;
	(void)outRef;

	if (inItemURL == NULL) {
		return paramErr;
	}

	// An item is already a URL to a file, so resolving it is handing back the
	// same URL. There is no alias to chase and no seed to report.
	if (outResolvedURL != NULL) {
		*outResolvedURL = (CFURLRef)CFRetain(inItemURL);
	}

	if (outRefSeed != NULL) {
		*outRefSeed = 0;
	}

	return noErr;
}

OSStatus LSSharedFileListCopySnapshot(LSSharedFileListRef inList, CFArrayRef* outSnapshot) {
	if (inList == NULL || outSnapshot == NULL) {
		return paramErr;
	}

	*outSnapshot = inList->items != NULL ? CFArrayCreateCopy(NULL, inList->items) : NULL;

	return *outSnapshot != NULL ? noErr : memFullErr;
}