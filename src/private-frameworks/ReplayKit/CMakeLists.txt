project(ReplayKit)

remove_sdk_framework(ReplayKit
    PRIVATE
)

set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "1.0.0")

set(FRAMEWORK_VERSION "A")

generate_sdk_framework(ReplayKit
    VERSION ${FRAMEWORK_VERSION}
    HEADER "include/ReplayKit"
    PRIVATE
)

add_framework(ReplayKit
	FAT
	CURRENT_VERSION
	PRIVATE
	VERSION ${FRAMEWORK_VERSION}

	SOURCES
		src/ReplayKit.m

	DEPENDENCIES
		system
		objc
		Foundation
)
