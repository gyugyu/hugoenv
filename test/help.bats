#!/usr/bin/env bats

load test_helper

@test "without args shows summary of common commands" {
  run hugoenv-help
  assert_success
  assert_line "Usage: hugoenv <command> [<args>]"
  assert_line "Some useful hugoenv commands are:"
}

@test "invalid command" {
  run hugoenv-help hello
  assert_failure
  assert_output "hugoenv: no such command \`hello'"
}

@test "shows help for a specific command" {
  mkdir -p "${HUGOENV_TEST_DIR}/bin"
  cat > "${HUGOENV_TEST_DIR}/bin/hugoenv-hello" <<SH
#!shebang
# Usage: hugoenv hello <world>
# Summary: Says "hello" to you, from hugoenv
# This command is useful for saying hello.
echo hello
SH

  run hugoenv-help hello
  assert_success
  assert_output - <<SH
Usage: hugoenv hello <world>

This command is useful for saying hello.
SH
}

@test "replaces missing extended help with summary text" {
  mkdir -p "${HUGOENV_TEST_DIR}/bin"
  cat > "${HUGOENV_TEST_DIR}/bin/hugoenv-hello" <<SH
#!shebang
# Usage: hugoenv hello <world>
# Summary: Says "hello" to you, from hugoenv
echo hello
SH

  run hugoenv-help hello
  assert_success
  assert_output - <<SH
Usage: hugoenv hello <world>

Says "hello" to you, from hugoenv
SH
}

@test "extracts only usage" {
  mkdir -p "${HUGOENV_TEST_DIR}/bin"
  cat > "${HUGOENV_TEST_DIR}/bin/hugoenv-hello" <<SH
#!shebang
# Usage: hugoenv hello <world>
# Summary: Says "hello" to you, from hugoenv
# This extended help won't be shown.
echo hello
SH

  run hugoenv-help --usage hello
  assert_success
  assert_output "Usage: hugoenv hello <world>"
}

@test "multiline usage section" {
  mkdir -p "${HUGOENV_TEST_DIR}/bin"
  cat > "${HUGOENV_TEST_DIR}/bin/hugoenv-hello" <<SH
#!shebang
# Usage: hugoenv hello <world>
#        hugoenv hi [everybody]
#        hugoenv hola --translate
# Summary: Says "hello" to you, from hugoenv
# Help text.
echo hello
SH

  run hugoenv-help hello
  assert_success
  assert_output - <<SH
Usage: hugoenv hello <world>
       hugoenv hi [everybody]
       hugoenv hola --translate

Help text.
SH
}

@test "multiline extended help section" {
  mkdir -p "${HUGOENV_TEST_DIR}/bin"
  cat > "${HUGOENV_TEST_DIR}/bin/hugoenv-hello" <<SH
#!shebang
# Usage: hugoenv hello <world>
# Summary: Says "hello" to you, from hugoenv
# This is extended help text.
# It can contain multiple lines.
#
# And paragraphs.

echo hello
SH

  run hugoenv-help hello
  assert_success
  assert_output - <<SH
Usage: hugoenv hello <world>

This is extended help text.
It can contain multiple lines.

And paragraphs.
SH
}
