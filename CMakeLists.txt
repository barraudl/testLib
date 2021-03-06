################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################

########################################################################
# Project setup
########################################################################
cmake_minimum_required(VERSION 2.8)
project(fty_test)
enable_language(CXX)
enable_testing()

set(SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
# Select flags
SET(CMAKE_C_FLAGS_RELEASE "-O3")

# Will be used to add flags to pkg-config useful when apps want to statically link
set(pkg_config_libs_private "")

########################################################################
# options
########################################################################
if (NOT CMAKE_BUILD_TYPE)
    if (EXISTS "${SOURCE_DIR}/.git")
        set (CMAKE_BUILD_TYPE Debug)
    else ()
# http://xit0.org/2013/04/cmake-use-git-branch-and-commit-details-in-project/
# http://stackoverflow.com/questions/6797395/cmake-execute-process-always-fails-with-no-such-file-or-directory-when-i-cal
        execute_process(
            COMMAND git rev-parse --show-toplevel
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
            RESULT_VARIABLE git_result
            OUTPUT_VARIABLE git_root
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        message(STATUS "git workspace root [${git_result}]: ${git_root}")
        if ( "${git_result}" == "0" )
            set (CMAKE_BUILD_TYPE Debug)
        else ()
            set (CMAKE_BUILD_TYPE Release)
        endif ()
    endif ()
endif ()
if (${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    OPTION (ENABLE_DRAFTS "Build and install draft classes and methods" ON)
else ()
    OPTION (ENABLE_DRAFTS "Build and install draft classes and methods" OFF)
endif ()
IF (ENABLE_DRAFTS)
    ADD_DEFINITIONS (-DFTY_TEST_BUILD_DRAFT_API)
ENDIF (ENABLE_DRAFTS)

########################################################################
# platform.h
########################################################################
include(CheckIncludeFile)
CHECK_INCLUDE_FILE("linux/wireless.h" HAVE_LINUX_WIRELESS_H)
CHECK_INCLUDE_FILE("net/if_media.h" HAVE_NET_IF_MEDIA_H)

include(CheckFunctionExists)
CHECK_FUNCTION_EXISTS("getifaddrs" HAVE_GETIFADDRS)
CHECK_FUNCTION_EXISTS("freeifaddrs" HAVE_FREEIFADDRS)

include(CheckIncludeFiles)
check_include_files("sys/socket.h;net/if.h" HAVE_NET_IF_H)
if (NOT HAVE_NET_IF_H)
    CHECK_INCLUDE_FILE("net/if.h" HAVE_NET_IF_H)
endif()

file(WRITE "${SOURCE_DIR}/src/platform.h.in" "
#cmakedefine HAVE_LINUX_WIRELESS_H
#cmakedefine HAVE_NET_IF_H
#cmakedefine HAVE_NET_IF_MEDIA_H
#cmakedefine HAVE_GETIFADDRS
#cmakedefine HAVE_FREEIFADDRS
")

configure_file("${SOURCE_DIR}/src/platform.h.in" "${SOURCE_DIR}/src/platform.h")

#The MSVC C compiler is too out of date,
#so the sources have to be compiled as c++
if (MSVC)
    enable_language(CXX)
    file(GLOB sources "${SOURCE_DIR}/src/*.cc")
    set_source_files_properties(
        ${sources}
        PROPERTIES LANGUAGE CXX
    )
    set(MORE_LIBRARIES ws2_32 Rpcrt4 Iphlpapi)
endif()

# specific case of windows UWP
if( ${CMAKE_SYSTEM_NAME} STREQUAL "WindowsStore" AND ${CMAKE_SYSTEM_VERSION} STREQUAL "10.0")
  ADD_DEFINITIONS(-DZMQ_HAVE_WINDOWS_UWP)
  ADD_DEFINITIONS(-D_WIN32_WINNT=_WIN32_WINNT_WIN10)
endif()


# required libraries for mingw
if (MINGW)
    set(MORE_LIBRARIES -lws2_32 -lrpcrt4 -liphlpapi)
endif()

# required libraries for cygwin
if (CYGWIN)
    set(MORE_LIBRARIES)
endif()

list(APPEND CMAKE_MODULE_PATH "${SOURCE_DIR}")
set(OPTIONAL_LIBRARIES)

########################################################################
# includes
########################################################################
set (fty_test_headers
    include/fty_test_library.h
    include/ftytest.h
    include/fty_test.h
)

source_group ("Header Files" FILES ${fty_test_headers})
install(FILES ${fty_test_headers} DESTINATION include)

########################################################################
# library
########################################################################
include_directories("${SOURCE_DIR}/src" "${SOURCE_DIR}/include")
set (fty_test_sources
    src/fty_test.cc
)
IF (ENABLE_DRAFTS)
    list (APPEND fty_test_sources
        src/fty_test_private_selftest.cc
    )
ENDIF (ENABLE_DRAFTS)

source_group("Source Files" FILES ${fty_test_sources})
if (NOT DEFINED BUILD_SHARED_LIBS)
    SET(BUILD_SHARED_LIBS ON)
endif()
add_library(fty_test ${fty_test_sources})
set_target_properties(fty_test
    PROPERTIES DEFINE_SYMBOL "FTY_TEST_EXPORTS"
)
set_target_properties (fty_test
    PROPERTIES SOVERSION "1"
)
set_target_properties (fty_test
    PROPERTIES VERSION "1.0.0"
)
target_link_libraries(fty_test
    ${ZEROMQ_LIBRARIES} ${MORE_LIBRARIES}
)

install(TARGETS fty_test
    LIBRARY DESTINATION "lib${LIB_SUFFIX}" # .so file
    ARCHIVE DESTINATION "lib${LIB_SUFFIX}" # .lib file
    RUNTIME DESTINATION bin              # .dll file
)

########################################################################
# pkgconfig
########################################################################
set (VERSION "1.0.0")
set (prefix "${CMAKE_INSTALL_PREFIX}")
set (exec_prefix "\${prefix}")
set (libdir "\${prefix}/lib${LIB_SUFFIX}")
set (includedir "\${prefix}/include")
IF (ENABLE_DRAFTS)
    set (pkg_config_defines "-DFTY_TEST_BUILD_DRAFT_API=1")
ELSE (ENABLE_DRAFTS)
    set (pkg_config_defines "")
ENDIF (ENABLE_DRAFTS)
configure_file(
    "${SOURCE_DIR}/src/libfty_test.pc.in"
    "${SOURCE_DIR}/src/libfty_test.pc"
@ONLY)

install(
    FILES "${SOURCE_DIR}/src/libfty_test.pc"
    DESTINATION "lib${LIB_SUFFIX}/pkgconfig"
)

########################################################################
# executables
########################################################################
add_executable(
    fty_test_selftest
    "${SOURCE_DIR}/src/fty_test_selftest.cc"
)
target_link_libraries(
    fty_test_selftest
    fty_test
    ${OPTIONAL_LIBRARIES}
)

########################################################################
# tests
########################################################################
set(CLASSTEST_TIMEOUT 60 CACHE STRING "Timeout of the selftest of a class")
set(TOTAL_TIMEOUT 600 CACHE STRING "Timout of the total testsuite")

if(UNIX)
    find_program(MEMORYCHECK_COMMAND valgrind)
    set(MEMORYCHECK_COMMAND_OPTIONS "--leak-check=full --show-reachable=yes
                                     --error-exitcode=1
                                     --suppressions=src/.valgrind.supp")
endif()

set(TEST_CLASSES
    fty_test
)

IF (ENABLE_DRAFTS)
    list (APPEND TEST_CLASSES
    private_classes
    )
ENDIF (ENABLE_DRAFTS)


add_custom_target(
    copy-selftest-ro ALL
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/src/selftest-ro ${CMAKE_BINARY_DIR}/src/selftest-ro
)

add_custom_target(
    make-selftest-rw ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/src/selftest-rw
)

set_directory_properties(
    PROPERTIES
    ADDITIONAL_MAKE_CLEAN_FILES "${CMAKE_BINARY_DIR}/src/selftest-ro;${CMAKE_BINARY_DIR}/src/selftest-rw"
)

foreach(TEST_CLASS ${TEST_CLASSES})
    add_test(
        NAME ${TEST_CLASS}
        COMMAND fty_test_selftest --continue --verbose --test ${TEST_CLASS}
    )
    set_tests_properties(
        ${TEST_CLASS}
        PROPERTIES TIMEOUT ${CLASSTEST_TIMEOUT}
    )
    set_tests_properties(
        ${TEST_CLASS}
        PROPERTIES DEPENDS "copy-selftest-ro;make-selftest-rw"
    )
endforeach(TEST_CLASS)

include(CTest)

########################################################################
# cleanup
########################################################################
add_custom_target (distclean @echo Cleaning for source distribution)

set(cmake_generated ${CMAKE_BINARY_DIR}/CMakeCache.txt
                    ${CMAKE_BINARY_DIR}/cmake_install.cmake
                    ${CMAKE_BINARY_DIR}/Makefile
                    ${CMAKE_BINARY_DIR}/CMakeFiles
                    ${CMAKE_BINARY_DIR}/CTestTestfile.cmake
                    ${CMAKE_BINARY_DIR}/DartConfiguration.tcl
                    ${CMAKE_BINARY_DIR}/Testing
                    ${CMAKE_BINARY_DIR}/compile_commands.json
                    ${CMAKE_BINARY_DIR}/src/platform.h
                    ${CMAKE_BINARY_DIR}/src/libfty_test.pc
                    ${CMAKE_BINARY_DIR}/src/libfty_test.so
                    ${CMAKE_BINARY_DIR}/src/fty-test_selftest
                    ${CMAKE_BINARY_DIR}/src/fty_test_selftest
)

add_custom_command(
    DEPENDS clean
    COMMENT "distribution clean"
    COMMAND rm
    ARGS    -rf CMakeTmp ${cmake_generated}
    TARGET  distclean
)

########################################################################
# summary
########################################################################
message ("")
message (STATUS "******************* Configuration Summary *******************")
message (STATUS "General:")
message (STATUS "  Version           :   ${VERSION}")
message (STATUS "  System            :   ${CMAKE_SYSTEM_NAME}")
message (STATUS "  C compiler        :   ${CMAKE_C_COMPILER}")
message (STATUS "  Debug C flags     :   ${CMAKE_C_FLAGS_DEBUG} ${CMAKE_C_FLAGS}")
message (STATUS "  Release C flags   :   ${CMAKE_C_FLAGS_RELEASE} ${CMAKE_C_FLAGS}")
message (STATUS "  Build type        :   ${CMAKE_BUILD_TYPE}")
IF (ENABLE_DRAFTS)
message (STATUS "  Draft API         :   Yes")
ELSE (ENABLE_DRAFTS)
message (STATUS "  Draft API         :   No")
ENDIF (ENABLE_DRAFTS)
message (STATUS "")
message (STATUS "Dependencies:")
include(FeatureSummary)
feature_summary (WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
message (STATUS "")
message (STATUS "Install:")
message (STATUS "  Install prefix    :" "${CMAKE_INSTALL_PREFIX}")
message (STATUS "")
message (STATUS "************************* Options ***************************")
message (STATUS "Options:")
message (STATUS "  Use the Draft API (default = yes):")
message (STATUS "  -DENABLE-DRAFTS=[yes|no]")
message (STATUS "")
message (STATUS "*************************************************************")
message (STATUS "Configuration complete! Now procced with:")
message (STATUS "  'make'                compile the project")
message (STATUS "  'make test'           run the project's selftest")
message (STATUS "  'make install'        install the project to ${CMAKE_INSTALL_PREFIX}")
message (STATUS "")
message (STATUS "Further options are:")
message (STATUS "  'ctest -T memcheck'   run the project's selftest with")
message (STATUS "                        valgrind to check for memory leaks")
message (STATUS "")

################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################
