
# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

function echo_red() {
    echo -e "\e[31m$1\e[0m"
}
function echo_orange() {
    echo -e "\e[33m$1\e[0m"
}
function echo_green() {
    echo -e "\e[32m$1\e[0m"
}
function echo_blue() {
    echo -e "\e[34m$1\e[0m"
}
function echo_purple() {
    echo -e "\e[35m$1\e[0m"
}
function echo_cyan() {
    echo -e "\e[36m$1\e[0m"
}
function echo_white() {
    echo -e "\e[37m$1\e[0m"
}



# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color | *-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
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
#unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm* | rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
    *) ;;
esac

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

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

aptstuff='bind9-dnsutils grc expect git mc nano neofetch cowsay asciinema net-tools htop cmatrix lolcat aewan bash-completion sudo silversearcher-ag python3 ansible neofetch'

if [ $(id -u) -eq 0 ]; then     # root
    alias aptmystuff='apt-get update && apt-get install -y $aptstuff'
else                            # non-root
    alias aptmystuff='sudo apt-get update && sudo apt-get install -y $aptstuff'
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -lAp -h --group-directories-first --color=auto'
alias la='ls -Aa'
alias l='ls -CF'

function lll() {
    myVAR="$*"
    if [ -z "$myVAR" ]; then
        myVAR="."
    fi
    myCOMMAND="unbuffer ls -lAp -h --group-directories-first --color=auto $myVAR | tail -n+2 | column -t -N Type\(1\)Own\(3\)Grp\(3\)Wrld\(3\),LnCnt,Own,Grp,Size,Month,Day,Time,Name,Link,Target"
    eval $myCOMMAND
}
PATH="$PATH:/usr/games"

function chownsub() {
    myVAR="$*"
    if [ -z "$myVAR" ]; then
        myVAR="."
    fi
    myCOMMAND="unbuffer chown -R www-data:www-data $myVAR"
    eval $myCOMMAND
}

# Asciinema
if ! [ -f ~/.config/asciinema/install-id ]; then
    mkdir -p ~/.config/asciinema
    echo "33592392-0bb7-4fc1-a4d9-718c519ae737" >>~/.config/asciinema/install-id
fi
export ASCIINEMA_API_URL=https://asciinema.oconsys.net

function record(){
    TITLE="$*"
    if [ -z "$TITLE" ]; then
        echo "Usage: record RecordTitle"
    else
        myCOMMAND="unbuffer asciinema rec -t $TITLE --overwrite -i 1 ~/"$TITLE".cast"
        eval "$myCOMMAND"
    fi
}

# nano ~/.bashrc and after leaving editor source the file
alias nbrc='nano ~/.bashrc && source ~/.bashrc'
# search history for command
alias higr='history | grep'
# copy with progress using rsync
alias cpv='rsync -ah --info=progress2'
# color ip output
alias ipa='ip a --color=auto'
# dmesg
alias dmesg='dmesg --color=always | less'
# netstat
alias net='grc netstat -lntp'
# services
alias services='grc systemctl list-units'

# Python VENV
# create new Python3 Virtual Environment in current Directory
alias ve='python3 -m venv ./venv'
# activate Python Virtual Environment
alias va='source ./venv/bin/activate'
# go to webserver Dir
alias www='cd /var/www/'

for cmd in g++ gas head make ld ping6 tail traceroute6 $( ls /usr/share/grc/ ); do
    cmd="${cmd##*conf.}"
    type "${cmd}" >/dev/null 2>&1 && alias "${cmd}"="$( which grc ) --colour=auto ${cmd}"
done

# Print Greeting
neofetch
alias | column -t -l 3 -N DEL,Alias,Command -s ' ','=' -H DEL
