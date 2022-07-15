#!/usr/bin/env bash
LOG="${HOME}/dotfiles.log"
GITHUB_USER="hclareth7"
GITHUB_REPO="dotfiles"
USER_GIT_AUTHOR_NAME="hclareth7"
USER_GIT_AUTHOR_EMAIL="hclareth7@gmail.com"
DIR="${HOME}/${GITHUB_REPO}"

_process() {
    echo "$(date) PROCESSING:  $@" >> $LOG
    printf "$(tput setaf 6) %s...$(tput sgr0)\n" "$@"
}

_success() {
  local message=$1
  printf "%s✓ Success:%s\n" "$(tput setaf 2)" "$(tput sgr0) $message"
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

    # Change to the dotfiles directory
    cd "${DIR}"
}

link_dotfiles() {
    # symlink files to the HOME directory.
    if [[ -f "${DIR}/." ]]; then
        _process "→ Symlinking dotfiles in /configs"

        # Set variable for list of files
        files="${DIR}/."

        # Store IFS separator within a temp variable
        OIFS=$IFS
        # Set the separator to a carriage return & a new line break
        # read in passed-in file and store as an array
        IFS=$'\r\n'
        links=($(cat "${files}"))

        # Loop through array of files 
        for index in ${!links[*]}
        do
            for link in ${links[$index]}
            do
                _process "→ Linking ${links[$index]}"
                # set IFS back to space to split string on
                IFS=$' '
                # create an array of line items
                file=(${links[$index]})
                # Create symbolic link
                ln -fs "${DIR}/${file[0]}" "${HOME}/${file[1]}"
            done
            # set separater back to carriage return & new line break
            IFS=$'\r\n'
        done

        # Reset IFS back
        IFS=$OIFS

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

setup_git_authorship() {
  GIT_AUTHOR_NAME=eval "git config user.name"
  GIT_AUTHOR_EMAIL=eval "git config user.email"

  if [[ ! -z "$GIT_AUTHOR_NAME" ]]; then
    _process "→ Setting up Git author"

    read USER_GIT_AUTHOR_NAME
    if [[ ! -z "$USER_GIT_AUTHOR_NAME" ]]; then
      GIT_AUTHOR_NAME="${USER_GIT_AUTHOR_NAME}"
      $(git config --global user.name "$GIT_AUTHOR_NAME")
    else
      _warning "No Git user name has been set.  Please update manually"
    fi

    read USER_GIT_AUTHOR_EMAIL
    if [[ ! -z "$USER_GIT_AUTHOR_EMAIL" ]]; then
      GIT_AUTHOR_EMAIL="${USER_GIT_AUTHOR_EMAIL}"
      $(git config --global user.email "$GIT_AUTHOR_EMAIL")
    else
      _warning "No Git user email has been set.  Please update manually"
    fi
  else
    _process "→ Git author already set, moving on..."
  fi
}

install() {
  download_dotfiles
  link_dotfiles
  install_zsh
  install_oh_my_zsh
  install_packages

  #setup_git_authorship
}

install