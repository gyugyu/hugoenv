#!/usr/bin/env bats

load test_helper

@test "creates shims and versions directories" {
  assert [ ! -d "${HUGOENV_ROOT}/shims" ]
  assert [ ! -d "${HUGOENV_ROOT}/versions" ]
  run hugoenv-init -
  assert_success
  assert [ -d "${HUGOENV_ROOT}/shims" ]
  assert [ -d "${HUGOENV_ROOT}/versions" ]
}

@test "auto rehash" {
  run hugoenv-init -
  assert_success
  assert_line "command hugoenv rehash 2>/dev/null"
}

@test "setup shell completions" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run hugoenv-init - bash
  assert_success
  assert_line "source '${root}/test/../libexec/../completions/hugoenv.bash'"
}

@test "detect parent shell" {
  SHELL=/bin/false run hugoenv-init -
  assert_success
  assert_line "export HUGOENV_SHELL=bash"
}

@test "detect parent shell from script" {
  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"
  cat > myscript.sh <<OUT
#!/bin/sh
eval "\$(hugoenv-init -)"
echo \$HUGOENV_SHELL
OUT
  chmod +x myscript.sh
  run ./myscript.sh
  assert_success
  assert_output "sh"
}

@test "skip shell completions (fish)" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run hugoenv-init - fish
  assert_success
  local line="$(grep '^source' <<<"$output")"
  [ -z "$line" ] || flunk "did not expect line: $line"
}

@test "posix shell instructions" {
  run hugoenv-init bash
  assert [ "$status" -eq 1 ]
  assert_line 'eval "$(hugoenv init - bash)"'
}

@test "fish instructions" {
  run hugoenv-init fish
  assert_failure 1
  assert_line 'status --is-interactive; and hugoenv init - fish | source'
}

@test "option to skip rehash" {
  run hugoenv-init - --no-rehash
  assert_success
  refute_line "hugoenv rehash 2>/dev/null"
}

@test "adds shims to PATH" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run hugoenv-init - bash
  assert_success
  assert_line -n 0 'export PATH="'${HUGOENV_ROOT}'/shims:${PATH}"'
}

@test "adds shims to PATH (fish)" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run hugoenv-init - fish
  assert_success
  assert_line -n 0 "set -gx PATH '${HUGOENV_ROOT}/shims' \$PATH"
}

@test "can add shims to PATH more than once" {
  export PATH="${HUGOENV_ROOT}/shims:$PATH"
  run hugoenv-init - bash
  assert_success
  assert_line -n 0 'export PATH="'${HUGOENV_ROOT}'/shims:${PATH}"'
}

@test "can add shims to PATH more than once (fish)" {
  export PATH="${HUGOENV_ROOT}/shims:$PATH"
  run hugoenv-init - fish
  assert_success
  assert_line -n 0 "set -gx PATH '${HUGOENV_ROOT}/shims' \$PATH"
}

@test "outputs sh-compatible syntax" {
  run hugoenv-init - bash
  assert_success
  assert_line '  case "$command" in'

  run hugoenv-init - zsh
  assert_success
  assert_line '  case "$command" in'
}

@test "outputs fish-specific syntax (fish)" {
  run hugoenv-init - fish
  assert_success
  assert_line '  switch "$command"'
  refute_line '  case "$command" in'
}
