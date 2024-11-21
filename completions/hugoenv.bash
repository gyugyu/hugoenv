_hugoenv() {
  COMPREPLY=()
  local word="${COMP_WORDS[COMP_CWORD]}"

  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(hugoenv commands)" -- "$word") )
  else
    local words=("${COMP_WORDS[@]}")
    unset "words[0]"
    unset "words[$COMP_CWORD]"
    local completions=$(hugoenv completions "${words[@]}")
    COMPREPLY=( $(compgen -W "$completions" -- "$word") )
  fi
}

complete -F _hugoenv hugoenv
