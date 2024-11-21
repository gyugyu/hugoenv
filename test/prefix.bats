#!/usr/bin/env bats

load test_helper

@test "prefix" {
  mkdir -p "${HUGOENV_TEST_DIR}/myproject"
  cd "${HUGOENV_TEST_DIR}/myproject"
  echo "1.2.3" > .node-version
  mkdir -p "${HUGOENV_ROOT}/versions/1.2.3"
  run hugoenv-prefix
  assert_success
  assert_output "${HUGOENV_ROOT}/versions/1.2.3"
}

@test "prefix for invalid version" {
  HUGOENV_VERSION="1.2.3" run hugoenv-prefix
  assert_failure
  assert_output "hugoenv: version \`1.2.3' not installed"
}

@test "prefix for system" {
  mkdir -p "${HUGOENV_TEST_DIR}/bin"
  touch "${HUGOENV_TEST_DIR}/bin/node"
  chmod +x "${HUGOENV_TEST_DIR}/bin/node"
  HUGOENV_VERSION="system" run hugoenv-prefix
  assert_success
  assert_output "$HUGOENV_TEST_DIR"
}

@test "prefix for system in /" {
  mkdir -p "${BATS_TEST_DIRNAME}/libexec"
  cat >"${BATS_TEST_DIRNAME}/libexec/hugoenv-which" <<OUT
#!/bin/sh
echo /bin/node
OUT
  chmod +x "${BATS_TEST_DIRNAME}/libexec/hugoenv-which"
  HUGOENV_VERSION="system" run hugoenv-prefix
  assert_success
  assert_output "/"
  rm -f "${BATS_TEST_DIRNAME}/libexec/hugoenv-which"
}

@test "prefix for invalid system" {
  PATH="$(path_without node)" run hugoenv-prefix system
  assert_failure
  assert_output - <<EOF
hugoenv: node: command not found
hugoenv: system version not found in PATH
EOF
}
