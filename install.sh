#!/bin/bash

set -eo pipefail

source ./functions.sh

echo
yellow "=========================================="
blue   "  natedillon/dotfiles"
echo   "  https://github.com/natedillon/dotfiles"
yellow "=========================================="

# Installer function
dotfiles_installer () {

  # Xcode Command Line Developer Tools
  info "Checking for Xcode Command Line Developer Tools..."
  if type xcode-select >&- && xpath=$( xcode-select --print-path ) && test -d "${xpath}" && test -x "${xpath}"; then
    success "Xcode Command Line Developer Tools are installed"
  else
    info "Installing Xcode Command Line Developer Tools..."
    xcode-select --install
  fi

  # Homebrew
  info "Checking for Homebrew..."
  if hash brew 2>/dev/null; then
    success "Homebrew is installed"
    info "Updating Homebrew..."
    brew update
  else
    info "Installing Homebrew..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  # Homebrew packages
  info "Installing Homebrew packages..."
  brew tap homebrew/bundle
  brew bundle --verbose --file="./brewfiles/Brewfile"

  # Homebrew Mac App Store apps
  info "Installing Mac App Store apps..."
  brew bundle --verbose --file="./brewfiles/Brewfile.mas"

  # Homebrew casks
  info "Installing Homebrew casks..."
  brew bundle --verbose --file="./brewfiles/Brewfile.casks"

  # git-lfs
  info "Setting up git-lfs..."
  git lfs install

  # Git config
  # Copy base gitconfig file
  # Run gitconfig script

  # Oh My Zsh
  info "Checking for Oh My Zsh..."
  if [ -d "$HOME/.oh-my-zsh" ]; then
    success "Oh My Zsh is installed"
    info "Updating Oh My Zsh..."
    upgrade_oh_my_zsh
  else
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # Grunt
  info "Installing Grunt..."
  npm install -g grunt-cli

  # Drush launcher
  info "Checking for Drush launcher..."
  if hash drush 2>/dev/null; then
    success "Drush launcher is installed"
  else
    info "Installing Drush launcher..."
    cd $HOME
    curl -OL https://github.com/drush-ops/drush-launcher/releases/latest/download/drush.phar
    chmod +x drush.phar
    sudo mv drush.phar /usr/local/bin/drush
    cd -
  fi

  # SSH keys
  info "Checking for SSH keys..."
  private_key=$HOME/.ssh/id_rsa
  public_key=$HOME/.ssh/id_rsa.pub
  if [ -f "$private_key" ]; then private_key_exists=true; else private_key_exists=false; fi
  if [ -f "$public_key" ];  then public_key_exists=true;  else public_key_exists=false;  fi
  if $private_key_exists && $public_key_exists; then
    success "SSH keys already exist"
    generate_keys=false
  elif $private_key_exists || $public_key_exists; then
    if ! $private_key_exists; then
      warning "Private SSH key does not exist"
    elif ! $public_key_exists; then
      warning "Public SSH key does not exist"
    fi
    while true; do
      read -p "Would you like to generate new SSH keys? This may overwrite existing keys. [y/n]: " input
      case $input in
        [yY][eE][sS]|[yY] ) generate_keys=true; break;;
        [nN][oO]|[nN] ) generate_keys=false; break;;
        * ) warning "Please answer yes [Y/y] or no [N/n].";;
      esac
    done
  else
    generate_keys=true
  fi
  if $generate_keys; then
    if $private_key_exists; then
      info "Making a backup of private SSH key..."
    elif $public_key_exists; then
      info "Making a backup of public SSH key..."
    fi
    info "Generating new SSH keys..."
  fi

  # Copy Apache config files
  #backup files
  #cp config/apache2/httpd.conf /etc/apache2
  #cp config/apache2/extra/httpd-userdir.conf /etc/apache2/extra
  #cp config/apache2/users/nate.conf /etc/apache2/users
  #sudo apachectl restart

  # Copy PHP config file
  #backup file
  #cp config/php/7.4/php.ini /usr/local/etc/php/7.4

  # MariaDB
  #info "Running MySQL setup..."
  #sudo /usr/local/bin/mysql_secure_installation

  # Copy phpMyAdmin config file
  #backup file
  #cp config/phpmyadmin/phpmyadmin.config.inc.php /usr/local/etc

  # Copy .zshrc to home directory
  #backup file
  #cp .zshrc $HOME
  #source $HOME/.zshrc

}


# Confirm the user would like to run the installer
echo
if [ "$1" == "--force" -o "$1" == "-f" ]; then
  run_installer=true
else
  while true; do
    read -p "This may overwrite existing files in your home directory. Are you sure? [y/n]: " input
    case $input in
      [yY][eE][sS]|[yY] ) run_installer=true; break;;
      [nN][oO]|[nN] ) run_installer=false; break;;
      * ) warning "Please answer yes [Y/y] or no [N/n].";;
    esac
  done
fi

# Run the installer
if $run_installer; then
  info "Running the installer..."
  dotfiles_installer
fi
