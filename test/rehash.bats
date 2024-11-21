#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin="${HUGOENV_ROOT}/versions/${1}/bin"
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "empty rehash" {
  assert [ ! -d "${HUGOENV_ROOT}/shims" ]
  run hugoenv-rehash
  assert_success
  refute_output
  assert [ -d "${HUGOENV_ROOT}/shims" ]
  rmdir "${HUGOENV_ROOT}/shims"
}

@test "non-writable shims directory" {
  mkdir -p "${HUGOENV_ROOT}/shims"
  chmod -w "${HUGOENV_ROOT}/shims"
  run hugoenv-rehash
  assert_failure
  assert_output "hugoenv: cannot rehash: ${HUGOENV_ROOT}/shims isn't writable"
}

@test "rehash in progress" {
  mkdir -p "${HUGOENV_ROOT}/shims"
  touch "${HUGOENV_ROOT}/shims/.hugoenv-shim"
  run hugoenv-rehash
  assert_failure
  assert_output "hugoenv: cannot rehash: ${HUGOENV_ROOT}/shims/.hugoenv-shim exists"
}

@test "creates shims" {
  create_executable "0.10.26" "node"
  create_executable "0.10.26" "npm"
  create_executable "0.11.11" "node"
  create_executable "0.11.11" "npm"

  assert [ ! -e "${HUGOENV_ROOT}/shims/node" ]
  assert [ ! -e "${HUGOENV_ROOT}/shims/npm" ]

  run hugoenv-rehash
  assert_success
  refute_output

  run ls "${HUGOENV_ROOT}/shims"
  assert_success
  assert_output - <<OUT
node
npm
OUT
}

@test "removes outdated shims" {
  mkdir -p "${HUGOENV_ROOT}/shims"
  touch "${HUGOENV_ROOT}/shims/oldshim1"
  chmod +x "${HUGOENV_ROOT}/shims/oldshim1"

  create_executable "2.0" "npm"
  create_executable "2.0" "node"

  run hugoenv-rehash
  assert_success
  refute_output

  assert [ ! -e "${HUGOENV_ROOT}/shims/oldshim1" ]
}

@test "do exact matches when removing stale shims" {
  create_executable "2.0" "unicorn_rails"
  create_executable "2.0" "rspec-core"

  hugoenv-rehash

  cp "$HUGOENV_ROOT"/shims/{rspec-core,rspec}
  cp "$HUGOENV_ROOT"/shims/{rspec-core,rails}
  cp "$HUGOENV_ROOT"/shims/{rspec-core,uni}
  chmod +x "$HUGOENV_ROOT"/shims/{rspec,rails,uni}

  run hugoenv-rehash
  assert_success
  refute_output

  assert [ ! -e "${HUGOENV_ROOT}/shims/rails" ]
  assert [ ! -e "${HUGOENV_ROOT}/shims/rake" ]
  assert [ ! -e "${HUGOENV_ROOT}/shims/uni" ]
}

@test "binary install locations containing spaces" {
  create_executable "dirname1 p247" "node"
  create_executable "dirname2 preview1" "npm"

  assert [ ! -e "${HUGOENV_ROOT}/shims/node" ]
  assert [ ! -e "${HUGOENV_ROOT}/shims/npm" ]

  run hugoenv-rehash
  assert_success
  refute_output

  run ls "${HUGOENV_ROOT}/shims"
  assert_success
  assert_output - <<OUT
node
npm
OUT
}

@test "carries original IFS within hooks" {
  create_hook rehash hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  IFS=$' \t\n' run hugoenv-rehash
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}

@test "sh-rehash in bash" {
  create_executable "2.0" "node"
  HUGOENV_SHELL=bash run hugoenv-sh-rehash
  assert_success
  assert_output "hash -r 2>/dev/null || true"
  assert [ -x "${HUGOENV_ROOT}/shims/node" ]
}

@test "sh-rehash in fish" {
  create_executable "2.0" "node"
  HUGOENV_SHELL=fish run hugoenv-sh-rehash
  assert_success
  refute_output
  assert [ -x "${HUGOENV_ROOT}/shims/node" ]
}
