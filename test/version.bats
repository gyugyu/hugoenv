#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${HUGOENV_ROOT}/versions/$1"
}

alias_version() {
  ln -sf "$HUGOENV_ROOT/versions/$2" "$HUGOENV_ROOT/versions/$1"
}

setup() {
  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"
}

@test "no version selected" {
  assert [ ! -d "${HUGOENV_ROOT}/versions" ]
  run hugoenv-version
  assert_success
  assert_output "system"
}

@test "using a symlink/alias" {
  create_version 1.9.3
  alias_version 1.9 1.9.3

  HUGOENV_VERSION=1.9 run hugoenv-version

  assert_success
  assert_output "1.9 => 1.9.3 (set by HUGOENV_VERSION environment variable)"
}

@test "links to links resolve the final target" {
  create_version 1.9.3
  alias_version 1.9 1.9.3
  alias_version 1 1.9

  HUGOENV_VERSION=1 run hugoenv-version

  assert_success
  assert_output "1 => 1.9.3 (set by HUGOENV_VERSION environment variable)"
}

@test "set by HUGOENV_VERSION" {
  create_version "1.9.3"
  HUGOENV_VERSION=1.9.3 run hugoenv-version
  assert_success
  assert_output "1.9.3 (set by HUGOENV_VERSION environment variable)"
}

@test "set by local file" {
  create_version "1.9.3"
  cat > ".node-version" <<<"1.9.3"
  run hugoenv-version
  assert_success
  assert_output "1.9.3 (set by ${PWD}/.node-version)"
}

@test "set by global file" {
  create_version "1.9.3"
  cat > "${HUGOENV_ROOT}/version" <<<"1.9.3"
  run hugoenv-version
  assert_success
  assert_output "1.9.3 (set by ${HUGOENV_ROOT}/version)"
}
