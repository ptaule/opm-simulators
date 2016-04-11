#!/bin/bash

function build_opm_simulators {
  # Build ERT
  pushd .
  mkdir -p $WORKSPACE/deps/ert
  cd $WORKSPACE/deps/ert
  git init .
  git remote add origin https://github.com/Ensembles/ert
  git fetch --depth 1 origin $ERT_REVISION:branch_to_build
  test $? -eq 0 || exit 1
  git checkout branch_to_build
  popd

  pushd .
  mkdir -p serial/build-ert
  cd serial/build-ert
  cmake $WORKSPACE/deps/ert/devel -DBUILD_APPLICATIONS=1 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$WORKSPACE/serial/install
  cmake --build . --target install
  popd

  # Build opm-common
  pushd .
  mkdir -p $WORKSPACE/deps/opm-common
  cd $WORKSPACE/deps/opm-common
  git init .
  git remote add origin https://github.com/OPM/opm-common
  git fetch --depth 1 origin $OPM_COMMON_REVISION:branch_to_build
  test $? -eq 0 || exit 1
  git checkout branch_to_build
  popd
  source $WORKSPACE/deps/opm-common/jenkins/build-opm-module.sh

  pushd .
  mkdir serial/build-opm-common
  cd serial/build-opm-common
  build_module "-DCMAKE_INSTALL_PREFIX=$WORKSPACE/serial/install" 0 $WORKSPACE/deps/opm-common
  test $? -eq 0 || exit 1
  popd

  # Build opm-parser
  clone_and_build_module opm-parser "-DCMAKE_PREFIX_PATH=$WORKSPACE/serial/install -DCMAKE_INSTALL_PREFIX=$WORKSPACE/serial/install" $OPM_PARSER_REVISION $WORKSPACE/serial
  test $? -eq 0 || exit 1

  # Build opm-material
  clone_and_build_module opm-material "-DCMAKE_PREFIX_PATH=$WORKSPACE/serial/install -DCMAKE_INSTALL_PREFIX=$WORKSPACE/serial/install" $OPM_MATERIAL_REVISION $WORKSPACE/serial
  test $? -eq 0 || exit 1

  # Build opm-core
  clone_and_build_module opm-core "-DCMAKE_PREFIX_PATH=$WORKSPACE/serial/install -DCMAKE_INSTALL_PREFIX=$WORKSPACE/serial/install" $OPM_CORE_REVISION $WORKSPACE/serial
  test $? -eq 0 || exit 1

  # Build opm-grid
  clone_and_build_module opm-grid "-DCMAKE_PREFIX_PATH=$WORKSPACE/serial/install -DCMAKE_INSTALL_PREFIX=$WORKSPACE/serial/install" $OPM_GRID_REVISION $WORKSPACE/serial
  test $? -eq 0 || exit 1

  # Build opm-output
  clone_and_build_module opm-output "-DCMAKE_PREFIX_PATH=$WORKSPACE/serial/install -DCMAKE_INSTALL_PREFIX=$WORKSPACE/serial/install" $OPM_OUTPUT_REVISION $WORKSPACE/serial
  test $? -eq 0 || exit 1

  # Setup opm-data
  source $WORKSPACE/deps/opm-common/jenkins/setup-opm-data.sh

  # Build opm-simulators
  pushd .
  mkdir serial/build-opm-simulators
  cd serial/build-opm-simulators
  build_module "-DCMAKE_PREFIX_PATH=$WORKSPACE/serial/install -DOPM_DATA_ROOT=$OPM_DATA_ROOT" 1 $WORKSPACE
  test $? -eq 0 || exit 1
  popd
}
