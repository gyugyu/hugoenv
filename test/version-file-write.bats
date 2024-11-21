#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"
}

@test "invocation without 2 arguments prints usage" {
  run hugoenv-version-file-write
  assert_failure
  assert_output "Usage: hugoenv version-file-write <file> <version>"
  run hugoenv-version-file-write "one" ""
  assert_failure
}

@test "setting nonexistent version fails" {
  assert [ ! -e ".node-version" ]
  run hugoenv-version-file-write ".node-version" "1.8.7"
  assert_failure
  assert_output "hugoenv: version \`1.8.7' not installed"
  assert [ ! -e ".node-version" ]
}

@test "writes value to arbitrary file" {
  mkdir -p "${HUGOENV_ROOT}/versions/1.8.7"
  assert [ ! -e "my-version" ]
  run hugoenv-version-file-write "${PWD}/my-version" "1.8.7"
  assert_success
  refute_output
  assert [ "$(cat my-version)" = "1.8.7" ]
}
