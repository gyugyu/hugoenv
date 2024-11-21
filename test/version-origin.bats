#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"
}

@test "reports global file even if it doesn't exist" {
  assert [ ! -e "${HUGOENV_ROOT}/version" ]
  run hugoenv-version-origin
  assert_success
  assert_output "${HUGOENV_ROOT}/version"
}

@test "detects global file" {
  mkdir -p "$HUGOENV_ROOT"
  touch "${HUGOENV_ROOT}/version"
  run hugoenv-version-origin
  assert_success
  assert_output "${HUGOENV_ROOT}/version"
}

@test "detects HUGOENV_VERSION" {
  HUGOENV_VERSION=1 run hugoenv-version-origin
  assert_success
  assert_output "HUGOENV_VERSION environment variable"
}

@test "detects local file" {
  echo "system" > .node-version
  run hugoenv-version-origin
  assert_success
  assert_output "${PWD}/.node-version"
}

@test "reports from hook" {
  create_hook version-origin test.bash <<<"HUGOENV_VERSION_ORIGIN=plugin"

  HUGOENV_VERSION=1 run hugoenv-version-origin
  assert_success
  assert_output "plugin"
}

@test "carries original IFS within hooks" {
  create_hook version-origin hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export HUGOENV_VERSION=system
  IFS=$' \t\n' run hugoenv-version-origin env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "doesn't inherit HUGOENV_VERSION_ORIGIN from environment" {
  HUGOENV_VERSION_ORIGIN=ignored run hugoenv-version-origin
  assert_success
  assert_output "${HUGOENV_ROOT}/version"
}
