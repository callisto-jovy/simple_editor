# jni_native_build (Build with jni:setup. Do not delete this line.)

# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(fast_edits_backend VERSION 0.0.1 LANGUAGES C)

add_library(fast_edits_backend SHARED
  "./fast_edits_backend.c"
)

set_target_properties(fast_edits_backend PROPERTIES
  OUTPUT_NAME "fast_edits_backend"
)

target_compile_definitions(fast_edits_backend PUBLIC DART_SHARED_LIB)

if(WIN32)
	set_target_properties(${TARGET_NAME} PROPERTIES
		LINK_FLAGS "/DELAYLOAD:jvm.dll")
endif()

if (ANDROID)
	target_link_libraries(fast_edits_backend log)
else()
	find_package(Java REQUIRED)
	find_package(JNI REQUIRED)
	include_directories(${JNI_INCLUDE_DIRS})
	target_link_libraries(fast_edits_backend ${JNI_LIBRARIES})
endif()
