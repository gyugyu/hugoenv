if [[ ! -o interactive ]]; then
    return
fi

compctl -K _hugoenv hugoenv

_hugoenv() {
  local words completions
  read -cA words

  if [ "${#words}" -eq 2 ]; then
    completions="$(hugoenv commands)"
  else
    completions="$(hugoenv completions ${words[2,-2]})"
  fi

  reply=("${(ps:\n:)completions}")
}
