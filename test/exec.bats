#!/usr/bin/env bats

load test_helper

create_executable() {
  name="${1?}"
  shift 1
  bin="${HUGOENV_ROOT}/versions/${HUGOENV_VERSION}/bin"
  mkdir -p "$bin"
  { if [ $# -eq 0 ]; then cat -
    else echo "$@"
    fi
  } | sed -Ee '1s/^ +//' > "${bin}/$name"
  chmod +x "${bin}/$name"
}

@test "fails with invalid version" {
  export HUGOENV_VERSION="2.0"
  run hugoenv-exec node -v
  assert_failure
  assert_output "hugoenv: version \`2.0' is not installed (set by HUGOENV_VERSION environment variable)"
}

@test "fails with invalid version set from file" {
  mkdir -p "$HUGOENV_TEST_DIR"
  cd "$HUGOENV_TEST_DIR"
  echo 1.9 > .node-version
  run hugoenv-exec npm
  assert_failure
  assert_output "hugoenv: version \`1.9' is not installed (set by $PWD/.node-version)"
}

@test "completes with names of executables" {
  export HUGOENV_VERSION="2.0"
  create_executable "node" "#!/bin/sh"
  create_executable "npm" "#!/bin/sh"

  hugoenv-rehash
  run hugoenv-completions exec
  assert_success
  assert_output - <<OUT
--help
node
npm
OUT
}

@test "carries original IFS within hooks" {
  create_hook exec hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export HUGOENV_VERSION=system
  IFS=$' \t\n' run hugoenv-exec env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "forwards all arguments" {
  export HUGOENV_VERSION="2.0"
  create_executable "node" <<SH
#!$BASH
echo \$0
for arg; do
  # hack to avoid bash builtin echo which can't output '-e'
  printf "  %s\\n" "\$arg"
done
SH

  run hugoenv-exec node -w "/path to/node script.rb" -- extra args
  assert_success
  assert_output - <<OUT
${HUGOENV_ROOT}/versions/2.0/bin/node
  -w
  /path to/node script.rb
  --
  extra
  args
OUT
}

@test "supports node -S <cmd>" {
  export HUGOENV_VERSION="2.0"

  # emulate `node -S' behavior
  create_executable "node" <<SH
#!$BASH
if [[ \$1 == "-S"* ]]; then
  found="\$(PATH="\${NODEPATH:-\$PATH}" which \$2)"
  # assert that the found executable has node for shebang
  if head -n1 "\$found" | grep node >/dev/null; then
    \$BASH "\$found"
  else
    echo "node: no Node script found in input (LoadError)" >&2
    exit 1
  fi
else
  echo 'node 2.0 (hugoenv test)'
fi
SH

  create_executable "npm" <<SH
#!/usr/bin/env node
echo hello npm
SH

  hugoenv-rehash
  run node -S npm
  assert_success
  assert_output "hello npm"
}
