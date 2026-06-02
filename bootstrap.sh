#!/usr/bin/env bash
set -euo pipefail

repo="${DOTFILES_REPO:-git@github.com:curare/dotfiles.git}"
dir="${DOTFILES_DIR:-$HOME/dotfiles}"
key="$HOME/.ssh/github"

activate_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    printf 'Homebrew installation did not provide a brew executable.\n' >&2
    exit 1
  fi
}

restore_github_key() {
  if [[ -f "$key" ]]; then
    return
  fi

  if ! brew list --cask bitwarden >/dev/null 2>&1; then
    brew install --cask bitwarden
  fi

  open -a Bitwarden
  printf '\nCopy the private key from Bitwarden item "GitHub personal SSH key".\n'
  printf 'Press Return after the key is on the clipboard: '
  read -r

  if ! pbpaste | grep -q '^-----BEGIN OPENSSH PRIVATE KEY-----$'; then
    printf 'Clipboard does not contain an OpenSSH private key.\n' >&2
    exit 1
  fi

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  umask 077
  pbpaste > "$key"
  chmod 600 "$key"
  pbcopy < /dev/null
  printf 'Restored %s and cleared the clipboard.\n' "$key"
}

activate_homebrew
restore_github_key

export GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

if [[ -d "$dir/.git" ]]; then
  git -C "$dir" pull --ff-only origin main
elif [[ -e "$dir" ]]; then
  printf 'Refusing to overwrite existing non-repository path: %s\n' "$dir" >&2
  exit 1
else
  git clone "$repo" "$dir"
fi

exec "$dir/install.sh"
