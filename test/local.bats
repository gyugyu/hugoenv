#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "${HUGOENV_TEST_DIR}/myproject"
  cd "${HUGOENV_TEST_DIR}/myproject"
}

@test "no version" {
  assert [ ! -e "${PWD}/.node-version" ]
  run hugoenv-local
  assert_failure
  assert_output "hugoenv: no local version configured for this directory"
}

@test "local version" {
  echo "1.2.3" > .node-version
  run hugoenv-local
  assert_success
  assert_output "1.2.3"
}

@test "discovers version file in parent directory" {
  echo "1.2.3" > .node-version
  mkdir -p "subdir" && cd "subdir"
  run hugoenv-local
  assert_success
  assert_output "1.2.3"
}

@test "ignores HUGOENV_DIR" {
  echo "1.2.3" > .node-version
  mkdir -p "$HOME"
  echo "2.0-home" > "${HOME}/.node-version"
  HUGOENV_DIR="$HOME" run hugoenv-local
  assert_success
  assert_output "1.2.3"
}

@test "sets local version" {
  mkdir -p "${HUGOENV_ROOT}/versions/1.2.3"
  run hugoenv-local 1.2.3
  assert_success
  refute_output
  assert [ "$(cat .node-version)" = "1.2.3" ]
}

@test "changes local version" {
  echo "1.0-pre" > .node-version
  mkdir -p "${HUGOENV_ROOT}/versions/1.2.3"
  run hugoenv-local
  assert_success
  assert_output "1.0-pre"
  run hugoenv-local 1.2.3
  assert_success
  refute_output
  assert [ "$(cat .node-version)" = "1.2.3" ]
}

@test "unsets local version" {
  touch .node-version
  run hugoenv-local --unset
  assert_success
  refute_output
  refute [ -e .node-version ]
}
