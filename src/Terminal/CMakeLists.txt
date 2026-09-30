project(Terminal)

if (COMPONENT_gui)
	add_darling_executable(Terminal
		AppDelegate.m
		TerminalView.m
		main.m
		tmt.c
	)

	target_compile_options(Terminal PRIVATE -fobjc-arc)

	target_link_libraries(Terminal
		AppKit
		CoreGraphics
		Foundation
		objc
	)

	install(TARGETS Terminal RUNTIME DESTINATION "libexec/darling/Applications/Terminal.app/Contents/MacOS")
	install(FILES Info.plist DESTINATION "libexec/darling/Applications/Terminal.app/Contents")
	install(FILES Terminal.png DESTINATION "libexec/darling/Applications/Terminal.app/Contents/Resources")
endif()
