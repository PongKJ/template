set dotenv-required := true
set positional-arguments := true

build_type := if env_var('PRESET') =~ '.*?debug.*?' {'Debug'} else {'Release'}
conanrun_file := './out/build/conf-'+env_var('PRESET') + '/conan/build/' + build_type + '/generators/conanrun.sh'
run_target_file := './out/build/conf-' + env_var('PRESET') + '/bin/' + env_var('LAUNCH_TARGET')

@conf:
  echo "Configuring..."
  cmake --preset=conf-$PRESET

@build:
  echo "Building..."
  cmake --build --preset=build-$PRESET --target $BUILD_TARGET

@test: build
  echo "Testing..."
  source {{conanrun_file}} && ctest --preset=test-$PRESET

@run *args='': build
  echo "Running..."
  source {{conanrun_file}} && {{run_target_file}} $@

@clean:
  echo "Cleaning..."
  rm -rf ./out/build

  @pack:
  echo "Packing..."


setup_env:

