export LANG="${LANG:-C.UTF-8}"

# Ensure user-local binaries are on PATH.
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$HOME/.local/bin:$PATH"

HISTFILE="${HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt append_history
setopt extended_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt share_history
setopt prompt_subst

bindkey -v
bindkey '^?' backward-delete-char

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

ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
export ZSH_COMPDUMP="${ZSH_COMPDUMP:-$ZSH_CACHE_DIR/.zcompdump}"
mkdir -p "$ZSH_CACHE_DIR" 2>/dev/null || true

autoload -Uz compinit
zmodload zsh/complist 2>/dev/null || true
if [ -s "$ZSH_COMPDUMP" ]; then
  compinit -C -d "$ZSH_COMPDUMP"
else
  compinit -d "$ZSH_COMPDUMP"
fi

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"
alias vim='nvim'
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

# Keep the prompt simple so SSH/browser terminals do not render raw control sequences.
PROMPT='%F{green}$(computer_prompt_name)%f %F{blue}%~%f %# '
