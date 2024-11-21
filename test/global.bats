#!/usr/bin/env bats

load test_helper

@test "default" {
  run hugoenv-global
  assert_success
  assert_output "system"
}

@test "read HUGOENV_ROOT/version" {
  mkdir -p "$HUGOENV_ROOT"
  echo "1.2.3" > "$HUGOENV_ROOT/version"
  run hugoenv-global
  assert_success
  assert_output "1.2.3"
}

@test "set HUGOENV_ROOT/version" {
  mkdir -p "$HUGOENV_ROOT/versions/1.2.3"
  run hugoenv-global "1.2.3"
  assert_success
  run hugoenv-global
  assert_success
  assert_output "1.2.3"
}

@test "fail setting invalid HUGOENV_ROOT/version" {
  mkdir -p "$HUGOENV_ROOT"
  run hugoenv-global "1.2.3"
  assert_failure
  assert_output "hugoenv: version \`1.2.3' not installed"
}

@test "unset (remove) HUGOENV_ROOT/version" {
  mkdir -p "$HUGOENV_ROOT"
  echo "1.2.3" > "$HUGOENV_ROOT/version"

  run hugoenv-global --unset
  assert_success

  refute [ -e $HUGOENV_ROOT/version ]
  run hugoenv-global
  assert_output "system"
}
