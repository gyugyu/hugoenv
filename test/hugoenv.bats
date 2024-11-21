#!/usr/bin/env bats

load test_helper

@test "blank invocation" {
  run hugoenv
  assert_failure
  assert_line -n 0 "$(hugoenv---version)"
}

@test "invalid command" {
  run hugoenv does-not-exist
  assert_failure
  assert_output "hugoenv: no such command \`does-not-exist'"
}

@test "default HUGOENV_ROOT" {
  HUGOENV_ROOT="" HOME=/home/will run hugoenv root
  assert_success
  assert_output "/home/will/.hugoenv"
}

@test "inherited HUGOENV_ROOT" {
  HUGOENV_ROOT=/opt/hugoenv run hugoenv root
  assert_success
  assert_output "/opt/hugoenv"
}

@test "default HUGOENV_DIR" {
  run hugoenv echo HUGOENV_DIR
  assert_output "$(pwd)"
}

@test "inherited HUGOENV_DIR" {
  dir="${BATS_TMPDIR}/myproject"
  mkdir -p "$dir"
  HUGOENV_DIR="$dir" run hugoenv echo HUGOENV_DIR
  assert_output "$dir"
}

@test "invalid HUGOENV_DIR" {
  dir="${BATS_TMPDIR}/does-not-exist"
  assert [ ! -d "$dir" ]
  HUGOENV_DIR="$dir" run hugoenv echo HUGOENV_DIR
  assert_failure
  assert_output "hugoenv: cannot change working directory to \`$dir'"
}

@test "adds its own libexec to PATH" {
  run hugoenv echo "PATH"
  assert_success
  assert_output "${BATS_TEST_DIRNAME%/*}/libexec:$PATH"
}

@test "adds plugin bin dirs to PATH" {
  mkdir -p "$HUGOENV_ROOT"/plugins/node-build/bin
  mkdir -p "$HUGOENV_ROOT"/plugins/hugoenv-each/bin
  run hugoenv echo -F: "PATH"
  assert_success
  assert_line -n 0 "${BATS_TEST_DIRNAME%/*}/libexec"
  assert_line -n 1 "${HUGOENV_ROOT}/plugins/hugoenv-each/bin"
  assert_line -n 2 "${HUGOENV_ROOT}/plugins/node-build/bin"
}

@test "HUGOENV_HOOK_PATH preserves value from environment" {
  HUGOENV_HOOK_PATH=/my/hook/path:/other/hooks run hugoenv echo -F: "HUGOENV_HOOK_PATH"
  assert_success
  assert_line -n 0 "/my/hook/path"
  assert_line -n 1 "/other/hooks"
  assert_line -n 2 "${HUGOENV_ROOT}/hugoenv.d"
}

@test "HUGOENV_HOOK_PATH includes hugoenv built-in plugins" {
  unset HUGOENV_HOOK_PATH
  run hugoenv echo "HUGOENV_HOOK_PATH"
  assert_success
  assert_output "${HUGOENV_ROOT}/hugoenv.d:${BATS_TEST_DIRNAME%/*}/hugoenv.d:/usr/local/etc/hugoenv.d:/etc/hugoenv.d:/usr/lib/hugoenv/hooks"
}
