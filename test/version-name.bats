#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${HUGOENV_ROOT}/versions/$1"
}

setup() {
  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"
}

@test "no version selected" {
  assert [ ! -d "${HUGOENV_ROOT}/versions" ]
  run hugoenv-version-name
  assert_success
  assert_output "system"
}

@test "system version is not checked for existence" {
  HUGOENV_VERSION=system run hugoenv-version-name
  assert_success
  assert_output "system"
}

@test "HUGOENV_VERSION can be overridden by hook" {
  create_version "1.8.7"
  create_version "1.9.3"
  create_hook version-name test.bash <<<"HUGOENV_VERSION=1.9.3"

  HUGOENV_VERSION=1.8.7 run hugoenv-version-name
  assert_success
  assert_output "1.9.3"
}

@test "carries original IFS within hooks" {
  create_hook version-name hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export HUGOENV_VERSION=system
  IFS=$' \t\n' run hugoenv-version-name env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "HUGOENV_VERSION has precedence over local" {
  create_version "1.8.7"
  create_version "1.9.3"

  cat > ".node-version" <<<"1.8.7"
  run hugoenv-version-name
  assert_success
  assert_output "1.8.7"

  HUGOENV_VERSION=1.9.3 run hugoenv-version-name
  assert_success
  assert_output "1.9.3"
}

@test "local file has precedence over global" {
  create_version "1.8.7"
  create_version "1.9.3"

  cat > "${HUGOENV_ROOT}/version" <<<"1.8.7"
  run hugoenv-version-name
  assert_success
  assert_output "1.8.7"

  cat > ".node-version" <<<"1.9.3"
  run hugoenv-version-name
  assert_success
  assert_output "1.9.3"
}

@test "missing version" {
  HUGOENV_VERSION=1.2 run hugoenv-version-name
  assert_failure
  assert_output "hugoenv: version \`1.2' is not installed (set by HUGOENV_VERSION environment variable)"
}

@test "version with prefix in name" {
  create_version "1.8.7"
  cat > ".node-version" <<<"node-1.8.7"
  run hugoenv-version-name
  assert_success
  assert_output "1.8.7"
}

@test "version with 'v' prefix in name" {
  create_version "4.1.0"
  cat > ".node-version" <<<"v4.1.0"
  run hugoenv-version-name
  assert_success
  assert_output "4.1.0"
}

@test "version with 'node-v' prefix in name" {
  create_version "4.1.0"
  cat > ".node-version" <<<"node-v4.1.0"
  run hugoenv-version-name
  assert_success
  assert_output "4.1.0"
}

@test "iojs version with 'v' prefix in name" {
  create_version "iojs-3.1.0"
  cat > ".node-version" <<<"iojs-v3.1.0"
  run hugoenv-version-name
  assert_success
  assert_output "iojs-3.1.0"
}
