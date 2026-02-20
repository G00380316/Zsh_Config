# Powerlevel10k Instant Prompt (disabled if causing issues)
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Zinit Setup
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "$ZINIT_HOME/zinit.zsh"

# Init completion
autoload -Uz compinit && compinit -u

# Improve completion reliability
fpath+=($HOME/.zfunc)

# Plugins with Turbo Mode
zinit ice lucid
zinit light romkatv/powerlevel10k
[[ -f $HOME/.p10k.zsh ]] && source $HOME/.p10k.zsh

#zinit ice wait lucid
#zinit light zsh-users/zsh-completions

zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# Zoxide with Turbo Mode
zinit ice wait lucid
zinit light ajeetdsouza/zoxide
eval "$(zoxide init zsh --cmd cd)"

# History
HISTSIZE=10000
HISTFILE=$HOME/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory sharehistory
setopt hist_ignore_all_dups hist_ignore_dups hist_ignore_space hist_save_no_dups hist_find_no_dups
setopt correct

# FZF
FZF_HOME="$HOME/.fzf"
[ ! -d "$FZF_HOME" ] && git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_HOME" && "$FZF_HOME/install" --all
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
export FZF_COMPLETION_TRIGGER='**'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Bindkeys
bindkey '^R' fzf-history-widget
bindkey '^E' fzf-file-widget
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^I' fzf-file-widget # Hit TAB twice to activate
bindkey -e

# FZF-tab Completion Styles
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Terminal Styling
# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
# pokemon-colorscripts --no-title -s -r #without fastfetch
pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
#

# Aliases
alias ls='lsd --color=auto'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias q='exit'
alias qa='exit'
alias e='exec zsh'
alias n='nvim'
alias ni='nvim $(fzf --preview="bat --color=always {}")'
alias lg='lazygit'
alias search='rg'
alias nosleep='caffeinate -d'
alias lg='lazygit'
alias docs="~/.config/scripts/cht.sh"
alias penv="python3 -m venv .venv"
alias senv="source .venv/bin/activate"
alias uzip='unzip'

# Functions
mkcd() { mkdir -p "$1" && cd "$1"; }

pip() { python3 -m pip install "$1" }

extract() {
  case "$1" in
    *.tar.bz2) tar xvjf "$1" ;;
    *.tar.gz)  tar xvzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *)         echo "Unsupported file: $1" ;;
  esac
}

checkPort(){
    lsof -i :"$1"
}

run() {
    # Exit if no file is provided
    if [[ -z "$1" ]]; then
        echo "Usage: run <filename>"
        return 1
    fi

    local file="$1"
    local base="${file%.*}" # Removes the last extension
    local ext="${file##*.}" # Gets the extension (e.g., c, cpp, py)

    case "$ext" in
        tex)
            xelatex --interaction=batchmode "$file" > /dev/null 2>&1 && open "${base}.pdf"
            ;;
        c)
            gcc "$file" -o "$base" && ./"$base"
            ;;
        cpp)
            g++ "$file" -o "$base" && ./"$base"
            ;;
        py)
            python3 "$file"
            ;;
        js)
            node "$file"
            ;;
        go)
            go run "$file"
            ;;
        java)
            javac "$file" && java "$base"
            ;;
        *)
            echo "Error: I don't know how to run '.$ext' files yet."
            return 1
            ;;
    esac
}

# Editor
export EDITOR=nvim
[[ -n $SSH_CONNECTION ]] && export EDITOR=vim

export TMPDIR=/tmp

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
