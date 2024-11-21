#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin="${HUGOENV_ROOT}/versions/${1}/bin"
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "finds versions where present" {
  create_executable "1.8" "node"
  create_executable "1.8" "npm"
  create_executable "2.0" "node"

  run hugoenv-whence node
  assert_success
  assert_output - <<OUT
1.8
2.0
OUT

  run hugoenv-whence npm
  assert_success
  assert_output "1.8"

}
