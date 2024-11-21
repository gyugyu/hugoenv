#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"
}

create_file() {
  mkdir -p "$(dirname "$1")"
  echo "system" > "$1"
}

@test "detects global 'version' file" {
  create_file "${HUGOENV_ROOT}/version"
  run hugoenv-version-file
  assert_success
  assert_output "${HUGOENV_ROOT}/version"
}

@test "prints global file if no version files exist" {
  refute [ -e "${HUGOENV_ROOT}/version" ]
  refute [ -e ".node-version" ]
  run hugoenv-version-file
  assert_success
  assert_output "${HUGOENV_ROOT}/version"
}

@test "in current directory" {
  create_file ".node-version"
  run hugoenv-version-file
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/.node-version"
}

@test "in parent directory" {
  create_file ".node-version"
  mkdir -p project
  cd project
  run hugoenv-version-file
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/.node-version"
}

@test "topmost file has precedence" {
  create_file ".node-version"
  create_file "project/.node-version"
  cd project
  run hugoenv-version-file
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/project/.node-version"
}

@test "HUGOENV_DIR has precedence over PWD" {
  create_file "widget/.node-version"
  create_file "project/.node-version"
  cd project
  HUGOENV_DIR="${HUGOENV_TEST_DIR}/widget" run hugoenv-version-file
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/widget/.node-version"
}

@test "PWD is searched if HUGOENV_DIR yields no results" {
  mkdir -p "widget/blank"
  create_file "project/.node-version"
  cd project
  HUGOENV_DIR="${HUGOENV_TEST_DIR}/widget/blank" run hugoenv-version-file
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/project/.node-version"
}

@test "finds version file in target directory" {
  create_file "project/.node-version"
  run hugoenv-version-file "${PWD}/project"
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/project/.node-version"
}

@test "fails when no version file in target directory" {
  run hugoenv-version-file "$PWD"
  assert_failure
  refute_output
}
