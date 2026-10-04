/*
 This file is part of Darling.

 Copyright (C) 2025 Darling Developers

 Darling is free software: you can redistribute it and/or modify
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

#ifndef _CORESERVICES_LSSHAREDFILELIST_H_
#define _CORESERVICES_LSSHAREDFILELIST_H_

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>

typedef struct OpaqueLSSharedFileListItemRef *LSSharedFileListItemRef;
typedef struct OpaqueLSSharedFileList *LSSharedFileListRef;

extern LSSharedFileListItemRef kLSSharedFileListItemLast;

/* A shared file list is a named list of items -- Recent Documents, Favourites --
 * that LaunchServices persists and resolves. What exists here is the list
 * itself: an in-memory array of URLs that lives as long as the caller holds it.
 * There is no persistence between launches, no icon resolution and no
 * per-user storage, so a caller that saves and reloads a list gets back only
 * what it put in during this session. */
OSStatus LSSharedFileListItemResolve(LSSharedFileListRef inList, CFURLRef inItemURL,
                                    CFURLRef* outResolvedURL, void* outRef, UInt32* outRefSeed);

OSStatus LSSharedFileListCopySnapshot(LSSharedFileListRef inList, CFArrayRef* outSnapshot);

LSSharedFileListRef LSSharedFileListCreate(CFUUIDRef inListIdentifier, CFArrayRef inListOrArray,
                                           CFArrayRef inImagesToHide);

void LSSharedFileListDeallocate(LSSharedFileListRef inList);
CFIndex LSSharedFileListGetCount(LSSharedFileListRef inList);

#endif
