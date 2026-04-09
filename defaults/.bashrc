case $- in
  *i*) ;;
  *) return ;;
esac

computer_prompt_base_name() {
  local name=""
  if [ -r /etc/microagent/machine-name ]; then
    IFS= read -r name </etc/microagent/machine-name || true
  elif [ -r /etc/hostname ]; then
    IFS= read -r name </etc/hostname || true
  elif [ -n "${COMPUTER_NAME:-}" ]; then
    name="${COMPUTER_NAME}"
  elif [ -n "${COMPUTER_HANDLE:-}" ]; then
    name="${COMPUTER_HANDLE}"
  fi
  if [ -z "$name" ]; then
    name="microagentcomputer"
  fi
  printf '%s' "$name"
}

computer_prompt_name() {
  printf '%s' "$(computer_prompt_base_name)"
}

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"
alias vim='nvim'
alias vi='nvim'
alias ls='eza --group-directories-first --icons=auto'
alias la='eza -a --group-directories-first --icons=auto'
alias ll='eza -lah --git --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --group-directories-first --icons=auto'

export PS1="\[\033[01;32m\]\$(computer_prompt_name)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
