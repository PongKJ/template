add_executable(json_parser main.cc json_parser.cpp)

target_link_libraries(json_parser PRIVATE myproject::myproject_options myproject::myproject_warnings)
target_link_system_libraries(
  json_parser
  PRIVATE
  fmt::fmt
  spdlog::spdlog
  jsoncpp
  dbg_macro
)

target_include_directories(json_parser PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")
