#!/usr/bin/env bats

load test_helper

@test "prints usage help given no argument" {
  run hugoenv-hooks
  assert_failure
  assert_output "Usage: hugoenv hooks <command>"
}

@test "prints list of hooks" {
  path1="${HUGOENV_TEST_DIR}/hugoenv.d"
  path2="${HUGOENV_TEST_DIR}/etc/hugoenv_hooks"
  HUGOENV_HOOK_PATH="$path1"
  create_hook exec "hello.bash"
  create_hook exec "ahoy.bash"
  create_hook exec "invalid.sh"
  create_hook which "boom.bash"
  HUGOENV_HOOK_PATH="$path2"
  create_hook exec "bueno.bash"

  HUGOENV_HOOK_PATH="$path1:$path2" run hugoenv-hooks exec
  assert_success
  assert_output - <<OUT
${HUGOENV_TEST_DIR}/hugoenv.d/exec/ahoy.bash
${HUGOENV_TEST_DIR}/hugoenv.d/exec/hello.bash
${HUGOENV_TEST_DIR}/etc/hugoenv_hooks/exec/bueno.bash
OUT
}

@test "supports hook paths with spaces" {
  path1="${HUGOENV_TEST_DIR}/my hooks/hugoenv.d"
  path2="${HUGOENV_TEST_DIR}/etc/hugoenv hooks"
  HUGOENV_HOOK_PATH="$path1"
  create_hook exec "hello.bash"
  HUGOENV_HOOK_PATH="$path2"
  create_hook exec "ahoy.bash"

  HUGOENV_HOOK_PATH="$path1:$path2" run hugoenv-hooks exec
  assert_success
  assert_output - <<OUT
${HUGOENV_TEST_DIR}/my hooks/hugoenv.d/exec/hello.bash
${HUGOENV_TEST_DIR}/etc/hugoenv hooks/exec/ahoy.bash
OUT
}

@test "resolves relative paths" {
  HUGOENV_HOOK_PATH="${HUGOENV_TEST_DIR}/hugoenv.d"
  create_hook exec "hello.bash"
  mkdir -p "$HOME"

  HUGOENV_HOOK_PATH="${HOME}/../hugoenv.d" run hugoenv-hooks exec
  assert_success
  assert_output "${HUGOENV_TEST_DIR}/hugoenv.d/exec/hello.bash"
}

@test "resolves symlinks" {
  path="${HUGOENV_TEST_DIR}/hugoenv.d"
  mkdir -p "${path}/exec"
  mkdir -p "$HOME"
  touch "${HOME}/hola.bash"
  ln -s "../../home/hola.bash" "${path}/exec/hello.bash"
  touch "${path}/exec/bright.sh"
  ln -s "bright.sh" "${path}/exec/world.bash"

  HUGOENV_HOOK_PATH="$path" run hugoenv-hooks exec
  assert_success
  assert_output - <<OUT
${HOME}/hola.bash
${HUGOENV_TEST_DIR}/hugoenv.d/exec/bright.sh
OUT
}
