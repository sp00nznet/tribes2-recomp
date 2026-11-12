# =============================================================================
# Tribes 2 (25034) - static recompilation host (32-bit, MSVC x86)
#
#   py -3 tools/catalog.py && py -3 run_lift.py
#   build.cmd                # vcvarsall amd64_x86 + CMake + Ninja -> build/tribes2.exe
#   build\tribes2.exe --run
# =============================================================================
cmake_minimum_required(VERSION 3.20)
# The C runtime linked in: a test VM has no 32-bit VC++ redistributable.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
project(tribes2 C)

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 4)
  message(FATAL_ERROR "the host must be 32-bit: use build.cmd (vcvarsall amd64_x86)")
endif()
if(NOT MSVC)
  message(FATAL_ERROR "runtime/native32 is MSVC x86 inline assembly")
endif()
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

set(PCRECOMP "${CMAKE_SOURCE_DIR}/../pcrecomp" CACHE PATH "pcrecomp checkout")
include(${PCRECOMP}/cmake/pcrecomp_gen.cmake)

add_executable(tribes2
  src/runtime/host.c
  ${PCRECOMP}/runtime/native32/native32.c
  ${PCRECOMP}/runtime/native32/modules32.c
  ${PCRECOMP}/runtime/recomp32/image_loader.c
  ${PCRECOMP}/runtime/recomp32/recomp_trace.c
)
# The generated C at /Od: the whole lift build in minutes, not the better
# part of an hour (-DPCRECOMP_GEN_OPT=ON for /O2).
pcrecomp_gen_sources(tribes2)
target_include_directories(tribes2 PRIVATE
  src/runtime src/recomp/gen ${PCRECOMP}/runtime/native32 ${PCRECOMP}/runtime/recomp32)
target_compile_definitions(tribes2 PRIVATE RECOMP_RETADDR=0u _CRT_SECURE_NO_WARNINGS
                                                RECOMP_FLAT_MEMORY RECOMP_LOCAL_REGS)
# Linked high and not relocatable, so the guest's 0x00400000..0x009F8000 is
# free. /NXCOMPAT is load-bearing: a native call into guest code faults, and
# that fault is the callback trampoline.
target_link_options(tribes2 PRIVATE /BASE:0x60000000 /FIXED:NO /DYNAMICBASE:NO
                                         /NXCOMPAT /LARGEADDRESSAWARE /STACK:0x40000
                                         /MANIFESTUAC:NO /MAP)
set_source_files_properties(src/runtime/host.c PROPERTIES COMPILE_OPTIONS "/W3")
target_link_libraries(tribes2 PRIVATE user32 gdi32 kernel32 winmm advapi32)

option(T2_TRACE "record a ring buffer of lifted function entries" OFF)
if(T2_TRACE)
  target_compile_definitions(tribes2 PRIVATE RECOMP_TRACE=1)
endif()
