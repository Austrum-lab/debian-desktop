case $- in
    *i*) ;;
      *) return;;
esac
export HISTTIMEFORMAT='%F %T '
HISTCONTROL=ignoreboth
shopt -s checkwinsize cmdhist lithist histappend
HISTSIZE=5000
HISTFILESIZE=10000

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
export PATH=$HOME/.local/bin:$PATH
. "$HOME/.cargo/env"

export MAMBA_ROOT_PREFIX=/opt/_ai/_envs
export CONDA_PKGS_DIRS=/opt/_ai/_cache/conda
export PIP_CACHE_DIR=/opt/_ai/_cache/pip

eval "$(/opt/_ai/_mm/bin/micromamba shell hook --shell bash)"
mm(){ micromamba "$@"; }

export LD_LIBRARY_PATH="/home/kaa/.tensornvme/lib:$LD_LIBRARY_PATH"

alias sudo='sudo -E'
