set windows-shell := ["C:\\Program Files\\Git\\bin\\bash.exe", "-c"]
set dotenv-required := true
set positional-arguments := true

project_name := env_var('PROJECT_NAME')
build_type := if env_var('PRESET') =~ '.*?debug.*?' {'Debug'} else {'Release'}
conanrun_file := './out/build/conf-'+env_var('PRESET') + '/conan/build/' + build_type + '/generators/conanrun.sh'
conanbuild_file := './out/build/conf-'+env_var('PRESET') + '/conan/build/' + build_type + '/generators/conanbuild.sh'
bin_dir := './out/build/conf-' + env_var('PRESET') + '/bin'

@conf:
  echo "Configuring..."
  cmake --preset=conf-$PRESET \
  -D{{project_name}}_PACKAGING_MAINTAINER_MODE=$PACKAGING_MAINTAINER_MODE \
  -D{{project_name}}_WARNINGS_AS_ERRORS=$WARNINGS_AS_ERRORS \
  -D{{project_name}}_ENABLE_SANITIZER_LEAK=$ENABLE_SANITIZER_LEAK \
  -D{{project_name}}_ENABLE_SANITIZER_UNDEFINED=$ENABLE_SANITIZER_UNDEFINED \
  -D{{project_name}}_ENABLE_SANITIZER_THREAD=$ENABLE_SANITIZER_THREAD \
  -D{{project_name}}_ENABLE_SANITIZER_MEMORY=$ENABLE_SANITIZER_MEMORY \
  -D{{project_name}}_ENABLE_UNITY_BUILD=$ENABLE_UNITY_BUILD \
  -D{{project_name}}_ENABLE_CLANG_TIDY=$ENABLE_CLANG_TIDY \
  -D{{project_name}}_ENABLE_CPPCHECK=$ENABLE_CPPCHECK \
  -D{{project_name}}_ENABLE_PCH=$ENABLE_PCH \
  -D{{project_name}}_ENABLE_CACHE=$ENABLE_CACHE \
  -D{{project_name}}_ENABLE_IPO=$ENABLE_IPO \
  -D{{project_name}}_ENABLE_SANITIZER_ADDRESS=$ENABLE_SANITIZER_ADDRESS \
  -D{{project_name}}_ENABLE_USER_LINKER=$ENABLE_USER_LINKER \
  -D{{project_name}}_ENABLE_COVERAGE=$ENABLE_COVERAGE \
  -D{{project_name}}_BUILD_FUZZ_TESTS=$BUILD_FUZZ_TESTS \
  -D{{project_name}}_ENABLE_HARDENING=$ENABLE_HARDENING \
  -D{{project_name}}_ENABLE_GLOBAL_HARDENING=$ENABLE_GLOBAL_HARDENING \
  -DGIT_SHA=$GIT_SHA
  ln -srf ./out/build/conf-$PRESET/compile_commands.json ./compile_commands.json

@build target=env_var('BUILD_TARGET'):
  #!/usr/bin/env bash
  echo "Building {{target}} ..."
  source {{conanbuild_file}} && cmake --build --preset=build-$PRESET --target {{target}}

@test: (build "all")
  #!/usr/bin/env bash
  echo "Testing..."
  source {{conanrun_file}} && ctest --preset=test-$PRESET

@run *args='': build
  #!/usr/bin/env bash
  echo "Running..."
  source {{conanrun_file}} && {{bin_dir}}/$LAUNCH_TARGET $@

@clean:(_remove_dir './out/build')
  echo "Cleaning..."

@pack: build
  echo "Packing..."
  cd ./out/build/conf-$PRESET && cpack

@_remove_dir dir:
  - [ -d {{dir}} ] && rm -rf {{dir}}

