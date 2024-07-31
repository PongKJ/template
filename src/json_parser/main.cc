#include <iostream>
#include <spdlog/common.h>
#include <spdlog/spdlog.h>
#include <json/json.h>
#include <dbg.h>
int main([[maybe_unused]] int argc, [[maybe_unused]] char *argv[])
{
  spdlog::set_level(spdlog::level::debug);
  spdlog::debug("hello world");
  std::cout << "hello world" << std::endl;
  dbg("hello world");
  return 0;
}
