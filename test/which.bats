#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin
  if [[ $1 == */* ]]; then bin="$1"
  else bin="${HUGOENV_ROOT}/versions/${1}/bin"
  fi
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "outputs path to executable" {
  create_executable "1.8" "node"
  create_executable "2.0" "npm"

  HUGOENV_VERSION=1.8 run hugoenv-which node
  assert_success
  assert_output "${HUGOENV_ROOT}/versions/1.8/bin/node"

  HUGOENV_VERSION=2.0 run hugoenv-which npm
  assert_success
  assert_output "${HUGOENV_ROOT}/versions/2.0/bin/npm"
}

@test "searches PATH for system version" {
  create_executable "${HUGOENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${HUGOENV_ROOT}/shims" "kill-all-humans"

  HUGOENV_VERSION=system run hugoenv-which kill-all-humans
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims prepended)" {
  create_executable "${HUGOENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${HUGOENV_ROOT}/shims" "kill-all-humans"

  PATH="${HUGOENV_ROOT}/shims:$PATH" HUGOENV_VERSION=system run hugoenv-which kill-all-humans
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims appended)" {
  create_executable "${HUGOENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${HUGOENV_ROOT}/shims" "kill-all-humans"

  PATH="$PATH:${HUGOENV_ROOT}/shims" HUGOENV_VERSION=system run hugoenv-which kill-all-humans
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims spread)" {
  create_executable "${HUGOENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${HUGOENV_ROOT}/shims" "kill-all-humans"

  PATH="${HUGOENV_ROOT}/shims:${HUGOENV_ROOT}/shims:/tmp/non-existent:$PATH:${HUGOENV_ROOT}/shims" \
    HUGOENV_VERSION=system run hugoenv-which kill-all-humans
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/bin/kill-all-humans"
}

@test "doesn't include current directory in PATH search" {
  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"
  touch kill-all-humans
  chmod +x kill-all-humans
  PATH="$(path_without "kill-all-humans")" HUGOENV_VERSION=system run hugoenv-which kill-all-humans
  assert_failure
  assert_output "hugoenv: kill-all-humans: command not found"
}

@test "version not installed" {
  create_executable "2.0" "npm"
  HUGOENV_VERSION=1.9 run hugoenv-which npm
  assert_failure
  assert_output "hugoenv: version \`1.9' is not installed (set by HUGOENV_VERSION environment variable)"
}

@test "no executable found" {
  create_executable "1.8" "npm"
  HUGOENV_VERSION=1.8 run hugoenv-which node
  assert_failure
  assert_output "hugoenv: node: command not found"
}

@test "no executable found for system version" {
  PATH="$(path_without "mocha")" HUGOENV_VERSION=system run hugoenv-which mocha
  assert_failure
  assert_output "hugoenv: mocha: command not found"
}

@test "executable found in other versions" {
  create_executable "1.8" "node"
  create_executable "1.9" "npm"
  create_executable "2.0" "npm"

  HUGOENV_VERSION=1.8 run hugoenv-which npm
  assert_failure
  assert_output - <<OUT
hugoenv: npm: command not found

The \`npm' command exists in these Node versions:
  1.9
  2.0
OUT
}

@test "carries original IFS within hooks" {
  create_hook which hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  IFS=$' \t\n' HUGOENV_VERSION=system run hugoenv-which anything
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}

@test "discovers version from hugoenv-version-name" {
  mkdir -p "$HUGOENV_ROOT"
  cat > "${HUGOENV_ROOT}/version" <<<"1.8"
  create_executable "1.8" "node"

  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"

  HUGOENV_VERSION= run hugoenv-which node
  assert_success
  assert_output "${HUGOENV_ROOT}/versions/1.8/bin/node"
}
