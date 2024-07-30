include(cmake/CPM.cmake)

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(myproject_setup_dependencies)
  if("${CPM_SOURCE_CACHE}" STREQUAL "OFF")
    message(STATUS "CPM:Use default cache path(.cache/CPM)")
    set(CPM_SOURCE_CACHE ".cache/CPM")
  endif()
  # For each dependency, see if it's
  # already been provided to us by a parent project

  if(NOT TARGET fmtlib::fmtlib)
    cpmaddpackage(
      NAME
      fmt
      GIT_SHALLOW
      ON
      GITHUB_REPOSITORY
      fmtlib/fmt
      GIT_TAG
      11.0.2)
  endif()

  if(NOT TARGET Catch2::Catch2WithMain)
    cpmaddpackage(
      NAME
      Catch2
      GIT_SHALLOW
      ON
      GITHUB_REPOSITORY
      catchorg/Catch2
      GIT_TAG
      v3.6.0)
  endif()

  if(NOT TARGET CLI11::CLI11)
    cpmaddpackage(
      NAME
      CLI11
      GIT_SHALLOW
      ON
      GITHUB_REPOSITORY
      CLIUtils/CLI11
      GIT_TAG
      v2.4.2)
  endif()

  if(NOT TARGET ftxui::screen)
    cpmaddpackage(
      NAME
      ftxui
      GIT_SHALLOW
      ON
      GITHUB_REPOSITORY
      ArthurSonzogni/FTXUI
      GIT_TAG
      v5.0.0)
  endif()

  if(NOT TARGET tools::tools)
    cpmaddpackage(
      NAME
      tools
      GIT_SHALLOW
      ON
      GITHUB_REPOSITORY
      lefticus/tools
      GIT_TAG
      update_build_system)
  endif()

  if(NOT TARGET abseil::abseil)
    cpmaddpackage(
      NAME
      abseil
      GIT_SHALLOW
      ON
      GITHUB_REPOSITORY
      abseil/abseil-cpp
      GIT_TAG
      20240116.2)
  endif()

  if(NOT TARGET spdlog::spdlog)
    cpmaddpackage(
      NAME
      spdlog
      GIT_SHALLOW
      ON
      GITHUB_REPOSITORY
      gabime/spdlog
      GIT_TAG
      v1.14.1)

  endif()

  # for big packages,we can use the following way to add them
  if(NOT TARGET Boost::Boost)
    cpmaddpackage(
      NAME
      Boost
      VERSION
      1.85.0
      URL
      https://github.com/boostorg/boost/releases/download/boost-1.85.0/boost-1.85.0-cmake.tar.xz)
  endif()

  if(NOT TARGET dbg_macro::dbg_macro)
    cpmaddpackage(
      NAME
      dbg_macro
      GIT_SHALLOW
      ON
      GITHUB_REPOSITORY
      sharkdp/dbg-macro
      GIT_TAG
      v0.5.1)
  endif()
endfunction()
