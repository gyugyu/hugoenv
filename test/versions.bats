#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${HUGOENV_ROOT}/versions/$1/bin"
}

setup() {
  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"
}

stub_system_node() {
  local stub="${HUGOENV_TEST_DIR}/bin/node"
  mkdir -p "$(dirname "$stub")"
  touch "$stub" && chmod +x "$stub"
}

@test "no versions installed" {
  stub_system_node
  assert [ ! -d "${HUGOENV_ROOT}/versions" ]
  run hugoenv-versions
  assert_success
  assert_output "* system"
}

@test "not even system node available" {
  PATH="$(path_without node)" run hugoenv-versions
  assert_failure
  assert_output "Warning: no Node detected on the system"
}

@test "bare output no versions installed" {
  assert [ ! -d "${HUGOENV_ROOT}/versions" ]
  run hugoenv-versions --bare
  assert_success
  refute_output
}

@test "single version installed" {
  stub_system_node
  create_version "1.9"
  run hugoenv-versions
  assert_success
  assert_output - <<OUT
* system
  1.9
OUT
}

@test "single version bare" {
  create_version "1.9"
  run hugoenv-versions --bare
  assert_success
  assert_output "1.9"
}

@test "multiple versions" {
  stub_system_node
  create_version "1.8.7"
  create_version "1.9.3"
  create_version "2.0.0"
  run hugoenv-versions
  assert_success
  assert_output - <<OUT
* system
  1.8.7
  1.9.3
  2.0.0
OUT
}

@test "multiple versions with no system node" {
  create_version "1.8.7"
  create_version "1.9.3"
  create_version "2.0.0"
  PATH="$(path_without node)" run hugoenv-versions
  assert_success
  assert_output - <<OUT
  1.8.7
  1.9.3
  2.0.0
OUT
}

@test "sorts semantically" {
  stub_system_node
  create_version "8.0.0"
  create_version "9.0.0"
  create_version "10.0.0"
  create_version "iojs-3.0.0"
  create_version "chakracore-8.0.0"
  run hugoenv-versions
  assert_success
  assert_output - <<OUT
* system
  8.0.0
  9.0.0
  10.0.0
  chakracore-8.0.0
  iojs-3.0.0
OUT
}

@test "indicates current version" {
  stub_system_node
  create_version "1.9.3"
  create_version "2.0.0"
  HUGOENV_VERSION=1.9.3 run hugoenv-versions
  assert_success
  assert_output - <<OUT
  system
* 1.9.3 (set by HUGOENV_VERSION environment variable)
  2.0.0
OUT
}

@test "bare doesn't indicate current version" {
  create_version "1.9.3"
  create_version "2.0.0"
  HUGOENV_VERSION=1.9.3 run hugoenv-versions --bare
  assert_success
  assert_output - <<OUT
1.9.3
2.0.0
OUT
}

@test "globally selected version" {
  stub_system_node
  create_version "1.9.3"
  create_version "2.0.0"
  cat > "${HUGOENV_ROOT}/version" <<<"1.9.3"
  run hugoenv-versions
  assert_success
  assert_output - <<OUT
  system
* 1.9.3 (set by ${HUGOENV_ROOT}/version)
  2.0.0
OUT
}

@test "per-project version" {
  stub_system_node
  create_version "1.9.3"
  create_version "2.0.0"
  cat > ".node-version" <<<"1.9.3"
  run hugoenv-versions
  assert_success
  assert_output - <<OUT
  system
* 1.9.3 (set by ${HUGOENV_TEST_DIR}/.node-version)
  2.0.0
OUT
}

@test "ignores non-directories under versions" {
  create_version "1.9"
  touch "${HUGOENV_ROOT}/versions/hello"

  run hugoenv-versions --bare
  assert_success
  assert_output "1.9"
}

@test "lists symlinks under versions" {
  create_version "1.8.7"
  ln -s "1.8.7" "${HUGOENV_ROOT}/versions/1.8"
  mkdir "${HUGOENV_ROOT}/versions/lts"
  ln -s "../1.8.7" "${HUGOENV_ROOT}/versions/lts/argon"

  run hugoenv-versions --bare
  assert_success
  assert_output - <<OUT
1.8
1.8.7
lts/argon
OUT
}

@test "doesn't list symlink aliases when --skip-aliases" {
  create_version "1.8.7"
  ln -s "1.8.7" "${HUGOENV_ROOT}/versions/1.8"
  mkdir -p moo/bin
  ln -s "${PWD}/moo" "${HUGOENV_ROOT}/versions/1.9"

  run hugoenv-versions --bare --skip-aliases
  assert_success

  assert_output - <<OUT
1.8.7
1.9
OUT
}

@test "recurses into lts subdirectory" {
  stub_system_node
  create_version "2.0.0"
  mkdir "${HUGOENV_ROOT}/versions/lts"
  create_version "lts/argon"
  ln -s "../2.0.0" "${HUGOENV_ROOT}/versions/lts/boron"

  HUGOENV_VERSION=2.0.0 run hugoenv-versions

  assert_success
  assert_output - <<OUT
  system
* 2.0.0 (set by HUGOENV_VERSION environment variable)
  lts/argon
  lts/boron
OUT
}

@test "does not recurse into non-lts subdirectories" {
  stub_system_node
  create_version "2.0.0"
  mkdir "${HUGOENV_ROOT}/versions/other"
  create_version "other/1.2.3"

  HUGOENV_VERSION=2.0.0 run hugoenv-versions

  assert_success
  assert_output - <<OUT
  system
* 2.0.0 (set by HUGOENV_VERSION environment variable)
OUT
}

@test "lists version named lts" {
  stub_system_node
  create_version "2.0.0"
  create_version "lts"

  HUGOENV_VERSION=2.0.0 run hugoenv-versions

  assert_success
  assert_output - <<OUT
  system
* 2.0.0 (set by HUGOENV_VERSION environment variable)
  lts
OUT
}

@test "lists alias named lts" {
  stub_system_node
  create_version "2.0.0"
  ln -s "2.0.0" "${HUGOENV_ROOT}/versions/lts"

  HUGOENV_VERSION=2.0.0 run hugoenv-versions

  assert_success
  assert_output - <<OUT
  system
* 2.0.0 (set by HUGOENV_VERSION environment variable)
  lts
OUT
}
