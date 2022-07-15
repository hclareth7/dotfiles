#!/usr/bin/env bash
LOG="${HOME}/dotfiles.log"
GITHUB_USER="hclareth7"
GITHUB_REPO="dotfiles"
DIR="${HOME}/${GITHUB_REPO}"

_process() {
    echo "$(date) PROCESSING:  $@" >> $LOG
    printf "$(tput setaf 6) %s...$(tput sgr0)\n" "$@"
}

_success() {
  local message=$1
  printf "%s✓ Success:%s\n" "$(tput setaf 2)" "$(tput sgr0) $message"
}

_decrypt_ssh_config(){
    _process "→ decrypting .ssh/config"
    gpg -d ${DIR}/configs/.ssh/config.gpg>${DIR}/configs/.ssh/config
    chmod 600 ${DIR}/configs/.ssh/config
    [[ $? ]] && _success ".ssh/config file decrypted succesfully"
}

download_dotfiles() {
    _process "→ Creating directory at ${DIR} and setting permissions"
    mkdir -p "${DIR}"

    _process "→ Downloading repository to /tmp directory"
    curl -#fLo /tmp/${GITHUB_REPO}.tar.gz "https://github.com/${GITHUB_USER}/${GITHUB_REPO}/tarball/master"

    _process "→ Extracting files to ${DIR}"
    tar -zxf /tmp/${GITHUB_REPO}.tar.gz --strip-components 1 -C "${DIR}"

    _process "→ Removing tarball from /tmp directory"
    rm -rf /tmp/${GITHUB_REPO}.tar.gz

    [[ $? ]] && _success "${DIR} created, repository downloaded and extracted"

    _decrypt_ssh_config
    # Change to the dotfiles directory
    cd "${DIR}"
}

link_dotfiles() {
    # symlink files to the HOME directory.
    if [[ -d "${DIR}/configs" ]]; then

        _process "→ Symlinking dotfiles in /configs"

        # Set variable for list of files
        files="${DIR}/configs"
        for index in $(ls -A ${files})
        do
            _process "→ Linking $index"
            # Create symbolic link
            ln -fs "${files}/$index" "${HOME}/$index"
        done

        source "${HOME}/.profile"
        [[ $? ]] && _success "All files have been copied"
    fi
}

install_zsh() {
  _process "→ Installing zsh"
  sudo apt install zsh
  

  _process "→ Setting zsh as default shell"
  sudo chsh -s $(which zsh)
  [[ $? ]] \
  && _success "Installed zsh"
}


install_packages() {
  if ! type -P 'apt' &> /dev/null; then
    _error "apt not found"
  else
    _process "→ Installing apt packages"

    # Set variable for list of apt packages
    apts="${DIR}/packages/apt"

    # Update and upgrade all packages
    _process "→ Updating and upgrading apt packages"
    sudo apt update -y
    sudo apt upgrade -y

    
    # Store IFS within a temp variable
    OIFS=$IFS

    # Set the separator to a carriage return & a new line break
    # read in passed-in file and store as an array
    IFS=$'\r\n' packages=($(cat "${apts}"))

    for index in ${!packages[*]}
    do
      # Test whether a Homebrew formula is already installed
      if ! sudo apt list ${packages[$index]} &> /dev/null; then
        sudo apt install ${packages[$index]}
      fi
    done

    # Reset IFS back
    IFS=$OIFS


    [[ $? ]] && _success "All apt packages installed and updated"
  fi
}

install_oh_my_zsh(){
    _process "→ Installing oh-my-zsh"
    sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
     [[ $? ]] \
    && _success "Installed oh-my-zsh"
}



install() {
  download_dotfiles
  link_dotfiles
  install_zsh
  install_oh_my_zsh
  install_packages
}
opt=$1


 if [[ "${opt}" == "update" ]]; then
    download_dotfiles
 else
    install
 fi