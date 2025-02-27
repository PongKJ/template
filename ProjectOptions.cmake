include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)

macro(template_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(template_setup_options)
  # NOTE: enable hardening may cause build failed in debug mode
  option(template_ENABLE_HARDENING "Enable hardening" OFF)
  option(template_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    template_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    template_ENABLE_HARDENING
    OFF)
  template_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR template_PACKAGING_MAINTAINER_MODE)
    option(template_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(template_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(template_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(template_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(template_ENABLE_IPO "Enable IPO/LTO" ON)
    option(template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(template_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(template_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(template_ENABLE_CACHE "Enable ccache" ON)
  endif()
  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      template_ENABLE_IPO
      template_WARNINGS_AS_ERRORS
      template_ENABLE_USER_LINKER
      template_ENABLE_SANITIZER_ADDRESS
      template_ENABLE_SANITIZER_LEAK
      template_ENABLE_SANITIZER_UNDEFINED
      template_ENABLE_SANITIZER_THREAD
      template_ENABLE_SANITIZER_MEMORY
      template_ENABLE_UNITY_BUILD
      template_ENABLE_CLANG_TIDY
      template_ENABLE_CPPCHECK
      template_ENABLE_COVERAGE
      template_ENABLE_PCH
      template_ENABLE_CACHE)
  endif()

  template_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED
     AND (template_ENABLE_SANITIZER_ADDRESS
          OR template_ENABLE_SANITIZER_THREAD
          OR template_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(template_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(template_global_options)
  if(template_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    template_enable_ipo()
  endif()

  template_supports_sanitizers()

  if(template_ENABLE_HARDENING AND template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN
       OR template_ENABLE_SANITIZER_UNDEFINED
       OR template_ENABLE_SANITIZER_ADDRESS
       OR template_ENABLE_SANITIZER_THREAD
       OR template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${template_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${template_ENABLE_SANITIZER_UNDEFINED}")
    template_enable_hardening(template_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(template_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(template_warnings INTERFACE)
  add_library(template_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  template_set_project_warnings(
    template_warnings
    ${template_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(template_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    template_configure_linker(template_options)
  endif()

  include(cmake/Sanitizers.cmake)
  template_enable_sanitizers(
    template_options
    ${template_ENABLE_SANITIZER_ADDRESS}
    ${template_ENABLE_SANITIZER_LEAK}
    ${template_ENABLE_SANITIZER_UNDEFINED}
    ${template_ENABLE_SANITIZER_THREAD}
    ${template_ENABLE_SANITIZER_MEMORY})

  set_target_properties(template_options PROPERTIES UNITY_BUILD ${template_ENABLE_UNITY_BUILD})

  if(template_ENABLE_PCH)
    target_precompile_headers(
      template_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(template_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    template_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(template_ENABLE_CLANG_TIDY)
    template_enable_clang_tidy(template_options ${template_WARNINGS_AS_ERRORS})
  endif()

  if(template_ENABLE_CPPCHECK)
    template_enable_cppcheck(${template_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(template_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    template_enable_coverage(template_options)
  endif()

  if(template_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(template_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(template_ENABLE_HARDENING AND NOT template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN
       OR template_ENABLE_SANITIZER_UNDEFINED
       OR template_ENABLE_SANITIZER_ADDRESS
       OR template_ENABLE_SANITIZER_THREAD
       OR template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    template_enable_hardening(template_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
