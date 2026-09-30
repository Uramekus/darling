/*
 * Copyright (C) 2022-2024 Zoe Knox <zoe@pixin.net>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <Foundation/NSSelectInputSource.h>
#import <Foundation/NSSocket.h>
#import "AppDelegate.h"

@implementation AppDelegate
- (AppDelegate *)init {
    // terminal window and view
    _view = [TerminalView new];
    NSRect frame = [_view frame];

    NSRect visible = [[NSScreen mainScreen] visibleFrame];
    frame.origin.x = visible.size.width / 2 - frame.size.width / 2;
    frame.origin.y = visible.size.height - frame.size.height - 100;

    _window = [[NSWindow alloc] initWithContentRect:frame
        styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    [_window setTitle:@"Terminal"];

    // Create standard menus
    NSMenu *mainMenu = [NSMenu new];
    [mainMenu setDelegate:self];
    [mainMenu setAutoenablesItems:YES];

    // --- App Menu (Terminal) ---
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Terminal"];
    [appMenu addItemWithTitle:@"About Terminal" action:NULL keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Preferences…" action:NULL keyEquivalent:@","];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Hide Terminal" action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit Terminal" action:@selector(terminate:) keyEquivalent:@"q"];
    NSMenuItem *appMenuItem = [mainMenu addItemWithTitle:@"Terminal" action:NULL keyEquivalent:@""];
    [appMenuItem setSubmenu:appMenu];

    // --- Shell Menu ---
    NSMenu *shellMenu = [[NSMenu alloc] initWithTitle:@"Shell"];
    [shellMenu addItemWithTitle:@"New Window" action:NULL keyEquivalent:@"n"];

    // Nested submenu: Shell -> New Window with Profile -> [...]
    NSMenuItem *profileItem = [shellMenu addItemWithTitle:@"New Window with Profile" action:NULL keyEquivalent:@""];
    NSMenu *profileMenu = [[NSMenu alloc] initWithTitle:@"New Window with Profile"];
    [profileMenu addItemWithTitle:@"Default" action:NULL keyEquivalent:@""];
    [profileMenu addItemWithTitle:@"Pro" action:NULL keyEquivalent:@""];
    [profileMenu addItemWithTitle:@"Homebrew" action:NULL keyEquivalent:@""];
    [profileMenu addItemWithTitle:@"Ocean" action:NULL keyEquivalent:@""];
    [profileItem setSubmenu:profileMenu];

    [shellMenu addItemWithTitle:@"New Tab" action:NULL keyEquivalent:@"t"];
    [shellMenu addItem:[NSMenuItem separatorItem]];
    [shellMenu addItemWithTitle:@"Close Window" action:@selector(performClose:) keyEquivalent:@"w"];
    NSMenuItem *shellMenuItem = [mainMenu addItemWithTitle:@"Shell" action:NULL keyEquivalent:@""];
    [shellMenuItem setSubmenu:shellMenu];

    // --- Edit Menu ---
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [editMenu addItem:[NSMenuItem separatorItem]];

    // Nested submenu: Edit -> Find -> [...]
    NSMenuItem *findItem = [editMenu addItemWithTitle:@"Find" action:NULL keyEquivalent:@""];
    NSMenu *findMenu = [[NSMenu alloc] initWithTitle:@"Find"];
    [findMenu addItemWithTitle:@"Find…" action:NULL keyEquivalent:@"f"];
    [findMenu addItemWithTitle:@"Find Next" action:NULL keyEquivalent:@"g"];
    [findMenu addItemWithTitle:@"Find Previous" action:NULL keyEquivalent:@"G"];
    [findMenu addItemWithTitle:@"Use Selection for Find" action:NULL keyEquivalent:@"e"];
    [findItem setSubmenu:findMenu];

    // Nested submenu: Edit -> Transformations -> [...]
    NSMenuItem *transItem = [editMenu addItemWithTitle:@"Transformations" action:NULL keyEquivalent:@""];
    NSMenu *transMenu = [[NSMenu alloc] initWithTitle:@"Transformations"];
    [transMenu addItemWithTitle:@"Make Upper Case" action:NULL keyEquivalent:@""];
    [transMenu addItemWithTitle:@"Make Lower Case" action:NULL keyEquivalent:@""];
    [transMenu addItemWithTitle:@"Capitalize" action:NULL keyEquivalent:@""];
    [transItem setSubmenu:transMenu];

    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Clear" action:NULL keyEquivalent:@"k"];
    NSMenuItem *editMenuItem = [mainMenu addItemWithTitle:@"Edit" action:NULL keyEquivalent:@""];
    [editMenuItem setSubmenu:editMenu];

    // --- View Menu ---
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    [viewMenu addItemWithTitle:@"Bigger Font" action:NULL keyEquivalent:@"+"];
    [viewMenu addItemWithTitle:@"Smaller Font" action:NULL keyEquivalent:@"-"];
    NSMenuItem *viewMenuItem = [mainMenu addItemWithTitle:@"View" action:NULL keyEquivalent:@""];
    [viewMenuItem setSubmenu:viewMenu];

    // --- Window Menu ---
    NSMenu *windows = [[NSMenu alloc] initWithTitle:@"Window"];
    [windows setValue:@"_NSWindowsMenu" forKey:@"name"];
    [windows setDelegate:self];
    [windows addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windows addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
    [windows addItem:[NSMenuItem separatorItem]];
    [windows addItemWithTitle:@"Bring All to Front" action:@selector(arrangeInFront:) keyEquivalent:@""];
    NSMenuItem *windowMenuItem = [mainMenu addItemWithTitle:@"Window" action:NULL keyEquivalent:@""];
    [windowMenuItem setSubmenu:windows];

    // --- Help Menu ---
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    [helpMenu addItemWithTitle:@"Terminal Help" action:NULL keyEquivalent:@"?"];
    NSMenuItem *helpMenuItem = [mainMenu addItemWithTitle:@"Help" action:NULL keyEquivalent:@""];
    [helpMenuItem setSubmenu:helpMenu];

    [NSApp setMenu:mainMenu];
    [NSApp addWindowsItem:_window title:[_window title] filename:NO];

    // allow terminal to be transparent :)
    [_window setBackgroundColor:[NSColor colorWithDeviceRed:1. green:1. blue:1. alpha:0]];

    [[_window contentView] addSubview:_view];
    [_window makeKeyAndOrderFront:self];

    return self;
}

- (void)setSize:(NSSize)size {
    NSRect frame = NSZeroRect;
    frame.size = size;
    [_window setFrame:frame display:YES];
    [_view setFrame:[_window contentRectForFrameRect:frame]];
}

- (void)setPTY:(int)pty {
    [_view setPTY:pty];
}

- (NSSize)terminalSize {
    return [_view terminalSize];
}

- (void)selectInputSource:(NSSelectInputSource *)inputSource selectEvent:(NSUInteger)selectEvent {
    [_view handlePTYInput];
}

@end

