load ../node_modules/bats-support/load
load ../node_modules/bats-assert/load

unset HUGOENV_VERSION
unset HUGOENV_DIR

# guard against executing this block twice due to bats internals
if [ -z "$HUGOENV_TEST_DIR" ]; then
  HUGOENV_TEST_DIR="${BATS_TMPDIR}/hugoenv"
  HUGOENV_TEST_DIR="$(mktemp -d "${HUGOENV_TEST_DIR}.XXX" 2>/dev/null || echo "$HUGOENV_TEST_DIR")"
  export HUGOENV_TEST_DIR

  HUGOENV_REALPATH=$BATS_TEST_DIRNAME/../libexec/hugoenv-realpath.dylib

  if enable -f "$HUGOENV_REALPATH" realpath 2>/dev/null; then
    HUGOENV_TEST_DIR="$(realpath "$HUGOENV_TEST_DIR")"
  else
    if [ -x "$HUGOENV_REALPATH" ]; then
      echo "hugoenv: failed to load \`realpath' builtin" >&2
      exit 1
    fi
  fi

  export HUGOENV_ROOT="${HUGOENV_TEST_DIR}/root"
  export HOME="${HUGOENV_TEST_DIR}/home"
  export HUGOENV_HOOK_PATH=$HUGOENV_ROOT/hugoenv.d:$BATS_TEST_DIRNAME/../hugoenv.d

  PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
  PATH="${HUGOENV_TEST_DIR}/bin:$PATH"
  PATH="${BATS_TEST_DIRNAME}/../libexec:$PATH"
  PATH="${BATS_TEST_DIRNAME}/libexec:$PATH"
  PATH="${HUGOENV_ROOT}/shims:$PATH"
  export PATH

  for xdg_var in $(env 2>/dev/null | grep ^XDG_ | cut -d= -f1); do unset "$xdg_var"; done
  unset xdg_var
fi

teardown() {
  rm -rf "$HUGOENV_TEST_DIR"
}

# Output a modified PATH that ensures that the given executable is not present,
# but in which system utils necessary for hugoenv operation are still available.
path_without() {
  local exe="$1"
  local path=":${PATH}:"
  local found alt util
  for found in $(type -aP "$exe"); do
    found="${found%/*}"
    if [ "$found" != "${HUGOENV_ROOT}/shims" ]; then
      alt="${HUGOENV_TEST_DIR}/$(echo "${found#/}" | tr '/' '-')"
      mkdir -p "$alt"
      for util in bash head cut readlink greadlink sed sort awk; do
        if [ -x "${found}/$util" ]; then
          ln -s "${found}/$util" "${alt}/$util"
        fi
      done
      path="${path/:${found}:/:${alt}:}"
    fi
  done
  path="${path#:}"
  echo "${path%:}"
}

create_hook() {
  local hook_path=${HUGOENV_HOOK_PATH%%:*}
  mkdir -p "${hook_path:?}/$1"
  touch "${hook_path:?}/$1/$2"
  if [ ! -t 0 ]; then
    cat > "${hook_path:?}/$1/$2"
  fi
}
