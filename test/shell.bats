#!/usr/bin/env bats

load test_helper

@test "shell integration disabled" {
  run hugoenv shell
  assert_failure
  assert_output "hugoenv: shell integration not enabled. Run \`hugoenv init' for instructions."
}

@test "shell integration enabled" {
  eval "$(hugoenv init -)"
  run hugoenv shell
  assert_success
  assert_output "hugoenv: no shell-specific version configured"
}

@test "no shell version" {
  mkdir -p "${HUGOENV_TEST_DIR}/myproject"
  cd "${HUGOENV_TEST_DIR}/myproject"
  echo "1.2.3" > .node-version
  HUGOENV_VERSION="" run hugoenv-sh-shell
  assert_failure
  assert_output "hugoenv: no shell-specific version configured"
}

@test "shell version" {
  HUGOENV_SHELL=bash HUGOENV_VERSION="1.2.3" run hugoenv-sh-shell
  assert_success
  assert_output 'echo "$HUGOENV_VERSION"'
}

@test "shell version (fish)" {
  HUGOENV_SHELL=fish HUGOENV_VERSION="1.2.3" run hugoenv-sh-shell
  assert_success
  assert_output 'echo "$HUGOENV_VERSION"'
}

@test "shell revert" {
  HUGOENV_SHELL=bash run hugoenv-sh-shell -
  assert_success
  assert_line -n 0 'if [ -n "${HUGOENV_VERSION_OLD+x}" ]; then'
}

@test "shell revert (fish)" {
  HUGOENV_SHELL=fish run hugoenv-sh-shell -
  assert_success
  assert_line -n 0 'if set -q HUGOENV_VERSION_OLD'
}

@test "shell unset" {
  HUGOENV_SHELL=bash run hugoenv-sh-shell --unset
  assert_success
  assert_output - <<OUT
HUGOENV_VERSION_OLD="\${HUGOENV_VERSION-}"
unset HUGOENV_VERSION
OUT
}

@test "shell unset (fish)" {
  HUGOENV_SHELL=fish run hugoenv-sh-shell --unset
  assert_success
  assert_output - <<OUT
set -gu HUGOENV_VERSION_OLD "\$HUGOENV_VERSION"
set -e HUGOENV_VERSION
OUT
}

@test "shell change invalid version" {
  run hugoenv-sh-shell 1.2.3
  assert_failure
  assert_output - <<SH
hugoenv: version \`1.2.3' not installed
false
SH
}

@test "shell change version" {
  mkdir -p "${HUGOENV_ROOT}/versions/1.2.3"
  HUGOENV_SHELL=bash run hugoenv-sh-shell 1.2.3
  assert_success
  assert_output - <<OUT
HUGOENV_VERSION_OLD="\${HUGOENV_VERSION-}"
export HUGOENV_VERSION="1.2.3"
OUT
}

@test "shell change version (fish)" {
  mkdir -p "${HUGOENV_ROOT}/versions/1.2.3"
  HUGOENV_SHELL=fish run hugoenv-sh-shell 1.2.3
  assert_success
  assert_output - <<OUT
set -gu HUGOENV_VERSION_OLD "\$HUGOENV_VERSION"
set -gx HUGOENV_VERSION "1.2.3"
OUT
}
