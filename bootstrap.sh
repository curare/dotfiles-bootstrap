#!/usr/bin/env bash
set -euo pipefail

repo="${DOTFILES_REPO:-git@github.com:curare/dotfiles.git}"
dir="${DOTFILES_DIR:-$HOME/dotfiles}"
key="$HOME/.ssh/github"

is_ssh_session() {
  [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

activate_homebrew() {
  if command_exists brew; then
    return
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

ensure_xcode_tools() {
  if ! xcode-select -p >/dev/null 2>&1; then
    printf 'Xcode Command Line Tools are missing. Starting installer...\n'
    xcode-select --install 2>/dev/null || true
    printf 'Finish the Command Line Tools installer, then press Return to continue: '
    read -r
    if ! xcode-select -p >/dev/null 2>&1; then
      printf 'Xcode Command Line Tools are still missing. Rerun this bootstrap after installation finishes.\n' >&2
      exit 1
    fi
  fi
}

ensure_homebrew() {
  activate_homebrew
  if command_exists brew; then
    return
  fi

  printf 'Homebrew is missing. Installing Homebrew...\n'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  activate_homebrew
  if ! command_exists brew; then
    printf 'Homebrew installation did not provide a brew executable in this shell.\n' >&2
    exit 1
  fi
}

ensure_bitwarden_for_console() {
  if is_ssh_session || [[ -d /Applications/Bitwarden.app ]]; then
    return
  fi

  printf 'Bitwarden is missing. Installing Bitwarden for key recovery...\n'
  brew install --cask bitwarden
}

validate_key_file() {
  local candidate="$1"

  if [[ "$(head -n 1 "$candidate")" != "-----BEGIN OPENSSH PRIVATE KEY-----" ]]; then
    printf 'SSH key does not start with an OpenSSH private key header.\n' >&2
    return 1
  fi
  if [[ "$(tail -n 1 "$candidate")" != "-----END OPENSSH PRIVATE KEY-----" ]]; then
    printf 'SSH key does not end with an OpenSSH private key footer.\n' >&2
    return 1
  fi
}

write_key_file() {
  local source_file="$1"

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  umask 077
  cp "$source_file" "$key"
  chmod 600 "$key"
  printf 'Restored %s.\n' "$key"
}

restore_github_key_from_clipboard() {
  local tmp

  open -a Bitwarden
  printf '\nCopy the private key from Bitwarden item "GitHub personal SSH key".\n'
  printf 'Press Return after the key is on the clipboard: '
  read -r

  tmp="$(mktemp /tmp/github-key.XXXXXX)"
  umask 077
  pbpaste > "$tmp"
  if ! validate_key_file "$tmp"; then
    rm -f "$tmp"
    exit 1
  fi
  write_key_file "$tmp"
  rm -f "$tmp"
  pbcopy < /dev/null
  printf 'Cleared the clipboard.\n'
}

restore_github_key_from_terminal() {
  local tmp line

  printf '\nPaste the GitHub OpenSSH private key, then press Return after the END line.\n'
  tmp="$(mktemp /tmp/github-key.XXXXXX)"
  umask 077
  while IFS= read -r line; do
    printf '%s\n' "$line" >> "$tmp"
    [[ "$line" == "-----END OPENSSH PRIVATE KEY-----" ]] && break
  done

  if ! validate_key_file "$tmp"; then
    rm -f "$tmp"
    exit 1
  fi
  write_key_file "$tmp"
  rm -f "$tmp"
}

ensure_github_key() {
  if [[ -f "$key" ]]; then
    return
  fi

  if is_ssh_session; then
    restore_github_key_from_terminal
  else
    restore_github_key_from_clipboard
  fi
}

verify_github_access() {
  local output

  output="$(ssh -i "$key" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)"
  if grep -Eq 'successfully authenticated|does not provide shell access' <<<"$output"; then
    return
  fi
  printf 'GitHub SSH authentication failed with %s.\n' "$key" >&2
  exit 1
}

clone_or_update_dotfiles() {
  export GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only origin main
  elif [[ -e "$dir" ]]; then
    printf 'Refusing to overwrite existing non-repository path: %s\n' "$dir" >&2
    exit 1
  else
    git clone "$repo" "$dir"
  fi
}

ensure_xcode_tools
ensure_homebrew
ensure_bitwarden_for_console
ensure_github_key
verify_github_access
clone_or_update_dotfiles

exec "$dir/install.sh"
