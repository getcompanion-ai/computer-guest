case $- in
  *i*) ;;
  *) return ;;
esac

computer_prompt_name() {
  printf '%s' "${COMPUTER_NAME:-${COMPUTER_HANDLE:-microagentcomputer}}"
}

alias ls='eza --group-directories-first --icons=auto'
alias la='eza -a --group-directories-first --icons=auto'
alias ll='eza -lah --git --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --group-directories-first --icons=auto'

export PS1="\[\033[01;32m\]\$(computer_prompt_name)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
