#!/bin/bash

# script variable initialization
CREATE_CONFIG="false"
CONTINUE="false"
SCRIPT_FULL_PATH="$(realpath "$0")"
SCRIPT_START_TIME=$(date +%Y-%m-%dT%Hh%Mm%Ss)
CONFIG_PATH="$CONFIG_PATH"
CONFIG_FILE="homeserver.yaml"
CONFIG_FULLNAME="$CONFIG_PATH/$CONFIG_FILE"
QUIT="false"
domain="matrix.yourdomain.de"

# script control
install_prerequisites="false"
service_enable="false"
config_overwrite="false"
config_check="true"

# Setup Variables
public_baseurl=https://$domain/
server_name="$domain"
matrix_port=8080
ReqPackages='ffmpeg build-essential python3-dev libffi-dev python3-pip python3-setuptools sqlite3 libssl-dev virtualenv libjpeg-dev libxslt1-dev libicu-dev libpq5 xxx'

registration_shared_secret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
dbname=matrixdb
dbuser=matrixdbuser
dbpass=pwmatrixdbpass

# Get the variable names using awk and store them in an array
function MENU() {
  VAR_NAMES=($(awk -F'=' '/^[a-z_][a-zA-Z0-9_]*=/ {print $1}' $SCRIPT_FULL_PATH))
  # region colors
  # Proxy echo commands for color output
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

  # Define inline ANSI Colors
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  ORANGE='\033[0;33m'
  BLUE='\033[0;34m'
  PURPLE='\033[0;35m'
  CYAN='\033[0;36m'
  WHITE='\033[0;37m'
  NC='\033[0m' # No Color
  # endregion
  clear
  echo_cyan '****************************'
  echo_cyan '* Matrix Synapse Installer *'
  echo_cyan '****************************'
  echo

  VAR_MENU=(${VAR_NAMES[*]})
  let NEXT_POS="${#VAR_MENU[*]}+1"
  VAR_MENU[$NEXT_POS]="Continue"
  let NEXT_POS="${#VAR_MENU[*]}+1"
  VAR_MENU[$NEXT_POS]="Quit"

  I=1
  for VARIABLE in "${VAR_MENU[@]}"; do
    VALUE=$(echo $VARIABLE | tr -d ' ')
    echo -e $WHITE$I $GREEN$VARIABLE $BLUE${!VALUE}
    let "I=I+1"
  done | column -t -N '#',Variable,Value -l 3

  echo_green "Select the setting you want to change:"
  select opt in "${VAR_MENU[@]}" Terminate; do
    case $opt in
    *)
      if [ $opt == "Continue" ]; then
        CONTINUE="true"
        break
      elif [ $opt == "Quit" ]; then
        QUIT="true"
        exit
      elif [ ${!opt} == "true" ]; then
        eval $opt=false
        break
      elif [ ${!opt} == "false" ]; then
        eval $opt=true
        break
      else
        echo "Enter new value for $opt:"
        echo "current value: "${!opt}
        read new_value
        eval $opt=$new_value
        break
      fi
      ;;
    $((${#VAR_MENU[@]} + 1)))
      echo "We're done!"
      break
      ;;
    esac
  done
  if [ $QUIT == "true" ]; then
    exit
  fi
}

while [ "$CONTINUE" != "true" ]; do
  public_baseurl=https://$domain/
  server_name="$domain"
  MENU
done

# check if an existing config file exists. Ask the user if they want to use or replace it, else exit
echo
echo_white 'checking for existing matrix config file in '$(echo_purple $CONFIG_FULLNAME)
if [ -f $CONFIG_FILE ]; then

  echo_orange 'existing config file was found under '$(echo_purple $CONFIG_FULLNAME)
  echo_white 'Do you want to '$(echo_green 'k_eep')' '$(echo_purple 'c_hange')' or '$(echo_red 'q_uit')?''
  echo_white 'a backup of the config '$(echo_purple $CONFIG_FULLNAME)' will be copied to '$(echo_green $(pwd)'/'$CONFIG_FILE'.bak-'$SCRIPT_START_TIME)''
  read USEEXISTING

  if [ $USEEXISTING == "k" ]; then
    echo_cyan 'Keeping existing config file'
  elif [ $USEEXISTING == "c" ]; then
    echo_cyan 'Creating new config'
    echo_green 'Creating Backup...'
    cp $CONFIG_FULLNAME "$(pwd)/$CONFIG_FILE.bak-$SCRIPT_START_TIME"
    echo_white 'backup of config '$(echo_purple $CONFIG_FULLNAME)' copied to '$(echo_green $(pwd)'/'$CONFIG_FILE'.bak-'$SCRIPT_START_TIME)''
    echo_green 'Done'
    CREATE_CONFIG="true"
  elif [ $USEEXISTING == "q" ]; then
    exit
  fi
else
  echo_green 'no pre-existing config file found.'
  echo
fi

echo $PREREQ_TEXT
# Check Prerequisites
CHECK_PREREQS() {
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  Orange='\033[0;33m'
  BLUE='\033[0;34m'
  PURPLE='\033[0;35m'
  CYAN='\033[0;36m'
  WHITE='\033[0;37m'
  NC='\033[0m' # No Color

  unset Packages
  declare -A Packages

  for Package in $ReqPackages; do
    unset Status
    unset InstallState
    InstallState=$(apt list --installed $Package 2>&- | sed "1 d")
    if [ -z "$InstallState" ]; then
      Status="${RED}missing${NC}"
    else
      Status="${GREEN}installed${NC}"
    fi
    Packages[$Package]="$Status"
  done
  for i in "${!Packages[@]}"; do
    echo -e "$i" "${Packages[$i]}"
  done
}

{ read -d '' message; } < <(CHECK_PREREQS)
echo
echo "${message}" | column -t -N Package,Status
echo
MISSING=$(echo $message | grep -c missing)
PREREQ_TEXT="There are $MISSING missing packages"

if [ $MISSING -gt 0 ]; then
  echo_white "Package Prerequisite Status: $MISSING missing package(s)"
  echo_white 'Do you want to install the missing packages? '$(echo_green 'I')'nstall '$(echo_orange 'S')'kip or '$(echo_red 'Q')'uit?'
  read INSTALLPACKAGES
else
  echo_green "$PREREQ_TEXT"
fi

if [ $INSTALLPACKAGES == "i" ]; then
  echo_green 'installing packages...'
  # Prerequisites
  # Add Key and PreRelease Repo
  echo_white 'Saving Matrix Keyring to: '$(echo_purple '/usr/share/keyrings/matrix-org-archive-keyring.gpg')
  wget -O /usr/share/keyrings/matrix-org-archive-keyring.gpg https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg 2>&-
  echo_green 'Done'
  echo
  echo_white 'Adding repository to file: '$(echo_purple '/etc/apt/sources.list.d/matrix-org.list')
  echo "deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main prerelease" | tee /etc/apt/sources.list.d/matrix-org.list
  echo_green 'Done'
  echo
  apt-get update
  apt-get install -y $ReqPackages
elif [ $INSTALLPACKAGES == "s" ]; then
  echo_white 'skipping package installation...'
elif [ $INSTALLPACKAGES == "q" ]; then
  exit
fi

if [ $CREATE_CONFIG == "true" ]; then
  echo_white 'Checking if directory '$(echo_purple '/etc/matrix-synapse/')' exists'
  if [ -d $CONFIG_PATH ]; then
    echo_green 'directory found.'
    echo
  else
    echo_orange 'directory not found. creating...'
    mkdir -p $CONFIG_PATH
    echo_green 'Done'
    echo
  fi
  cat >$CONFIG_PATH/homeserver.yaml <<EOF
server_name: "$server_name"
pid_file: "/var/run/matrix-synapse.pid"
listeners:
  - port: $matrix_port
    tls: false
    type: http
    x_forwarded: true
    bind_addresses: ['0.0.0.0']
    resources:
      - names: [client, federation]
        compress: false

email:
  smtp_host: mailcow.infraspread.net
  smtp_port: 587
  force_tls: true
  require_transport_security: true
  enable_tls: true
  smtp_user: "share@infraspread.net"
  smtp_pass: "#Share@Infra2024!"
  enable_notifs: false
  notif_for_new_users: true
  notif_from: "%(app)s <matrix@infraspread.net>"
  #client_base_url: https://element.infraspread.net/
  #invite_client_location: https://element.infraspread.net/
  app_name: Oconsys Matrix Server
  email_validation: "Oconsys Matrix: Email validation"

# Registration
enable_registration: false
enable_registration_captcha: false
registration_shared_secret: $registration_shared_secret
#recaptcha_public_key: 6Lfj_pEpAAAAAAsit2NbtLobH1889ij09Lvb_p54
#recaptcha_private_key: 6Lfj_pEpAAAAAEozZSKBlgMOHPas86dEEXtE5heW
# Third Party IDs
#registrations_require_3pid:
  #- email
#allowed_local_3pids:
  #- medium: email
    #pattern: '^[^@]+@infraspread\.net$'
  #- medium: email
    #pattern: '^[^@]+@oconsys\.net$'
  #- medium: email
    #pattern: '^[^@]+@hotmail\.com$'
  #- medium: email
    #pattern: '^[^@]+@outlook\.de$'
enable_3pid_changes: true
enable_set_avatar_url: true
enable_set_displayname: true

allow_guest_access: false

database:
  name: psycopg2
  txn_limit: 10000
  args:
    user: $dbuser
    password: $dbpass
    database: $dbname
    host: localhost
    port: 5432
    cp_min: 5
    cp_max: 10
log_config: "$CONFIG_PATH/log.yaml"
media_store_path: /var/lib/matrix-synapse/media
signing_key_path: "/etc/matrix-synapse/homeserver.signing.key"
trusted_key_servers:
  - server_name: "matrix.org"
suppress_key_server_warning: true
macaroon_secret_key: m98hET1OxsjMkRjrbCW0UBZGvFaQ2emB
public_baseurl: https://matrix.infraspread.net/
max_upload_size: 50M
url_preview_enabled: true
url_preview_ip_range_blacklist:
 - '127.0.0.0/8'
 - '10.0.0.0/8'
 - '172.16.0.0/12'
 - '192.168.0.0/16'
 - '100.64.0.0/10'
 - '192.0.0.0/24'
 - '169.254.0.0/16'
 - '::1/128'
 - 'fe80::/64'
 - 'fc00::/7'
EOF
fi

echo_white 'Checking the config file for errors...'
#python3 -m synapse.app.homeserver --config-path $CONFIG_PATH/homeserver.yaml --generate-config --report-stats=no
echo_green 'Done'

# ask if the user wants to enable the service
echo_white 'Do you want to enable/start the matrix-synapse service? '$(echo_green 'E')'nable '$(echo_red 'D')'isable or '$(echo_orange 'S')'kip?'
read ENABLESERVICE
if [ $ENABLESERVICE == "e" ]; then
  echo_green 'enabling service...'
  systemctl enable matrix-synapse.service && systemctl start matrix-synapse.service
  systemctl enable matrix-synapse.service
  echo_green 'Done'
elif [ $ENABLESERVICE == "d" ]; then
  echo_red 'disabling service...'
  systemctl disable matrix-synapse.service
  echo_green 'Done'
elif [ $ENABLESERVICE == "s" ]; then
  echo_white 'skipping service enablement...'
fi

#python -m synapse.config -c $CONFIG_PATH/homeserver.yaml
echo_purple 'End of Script'
