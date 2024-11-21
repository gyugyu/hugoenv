#!/usr/bin/env bats

load test_helper

@test "no shims" {
  run hugoenv-shims
  assert_success
  refute_output
}

@test "shims" {
  mkdir -p "${HUGOENV_ROOT}/shims"
  touch "${HUGOENV_ROOT}/shims/node"
  touch "${HUGOENV_ROOT}/shims/irb"
  run hugoenv-shims
  assert_success
  assert_line "${HUGOENV_ROOT}/shims/node"
  assert_line "${HUGOENV_ROOT}/shims/irb"
}

@test "shims --short" {
  mkdir -p "${HUGOENV_ROOT}/shims"
  touch "${HUGOENV_ROOT}/shims/node"
  touch "${HUGOENV_ROOT}/shims/irb"
  run hugoenv-shims --short
  assert_success
  assert_line "irb"
  assert_line "node"
}
