HISTFILE="${HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt append_history
setopt extended_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt share_history

bindkey -v

computer_prompt_name() {
  printf '%s' "${COMPUTER_NAME:-${COMPUTER_HANDLE:-microagentcomputer}}"
}

alias ls='eza --group-directories-first --icons=auto'
alias la='eza -a --group-directories-first --icons=auto'
alias ll='eza -lah --git --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --group-directories-first --icons=auto'

if [ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -r /opt/zsh/pure/pure.zsh ] && [ -r /opt/zsh/pure/async.zsh ]; then
  fpath=(/opt/zsh/pure $fpath)
  autoload -Uz promptinit
  promptinit
  if prompt pure >/dev/null 2>&1; then
    zstyle ':prompt:pure:path' color blue
    PROMPT='%F{green}$(computer_prompt_name)%f ${PROMPT}'
  else
    PROMPT='%F{green}$(computer_prompt_name)%f %F{blue}%~%f %# '
  fi
else
  PROMPT='%F{green}$(computer_prompt_name)%f %F{blue}%~%f %# '
fi
